"""Check local inline Markdown links and ATX heading anchors in current documentation.

This is navigation validation, not a CommonMark parser or a semantic governance checker.
Use inline links with URL-encoded spaces/parentheses and ATX headings in checked documents.
Reference links, HTML anchors, setext headings and remote URL availability are not checked.
Fenced/inline code and HTML comments are examples, not navigation. Historical documents
under knowledge/archive and plans/{completed,abandoned} are excluded from source checks.
"""

import argparse
import html
import re
import sys
from pathlib import Path
from urllib.parse import unquote, urlsplit

LINK = re.compile(r"\[([^\]\n]+)\]\(([^\s)]+)(?:\s+[^)]+)?\)")
FENCE = re.compile(r"^ {0,3}(`{3,}|~{3,})(.*)$")
HEADING = re.compile(r"^ {0,3}#{1,6}\s+(.+?)\s*#*\s*$", re.MULTILINE)
REQUIRED = (
    "README.md",
    "AGENTS.md",
    "CLAUDE.md",
    "knowledge/INDEX.md",
    "knowledge/governance/agent-entrypoint.md",
)


def prose(text: str) -> str:
    lines: list[str] = []
    marker = ""
    for line in re.sub(r"<!--.*?-->", "", text, flags=re.DOTALL).splitlines():
        match = FENCE.match(line)
        if marker:
            if (
                match
                and match[1][0] == marker[0]
                and len(match[1]) >= len(marker)
                and not match[2].strip()
            ):
                marker = ""
        elif match:
            marker = match[1]
        else:
            lines.append(line)
    return "\n".join(lines)


def links(text: str) -> list[str]:
    without_code = re.sub(r"(`+).*?\1", "", prose(text))
    return [match[2].strip("<>") for match in LINK.finditer(without_code)]


def anchors(text: str) -> set[str]:
    result: set[str] = set()
    for match in HEADING.finditer(prose(text)):
        title = LINK.sub(r"\1", html.unescape(match[1]))
        title = re.sub(r"<[^>]+>", "", title).lower()
        slug = re.sub(r"[^\w\- ]", "", title).replace(" ", "-")
        candidate = slug
        number = 0
        while candidate in result:
            number += 1
            candidate = f"{slug}-{number}"
        result.add(candidate)
    return result


def is_history(path: Path, knowledge: Path) -> bool:
    parts = path.relative_to(knowledge).parts
    return parts[0] == "archive" or (
        len(parts) > 2 and parts[0] == "plans" and parts[1] in {"completed", "abandoned"}
    )


def validate(root: Path) -> list[str]:
    root = root.resolve()
    errors = [f"missing {name}" for name in REQUIRED if not (root / name).is_file()]
    knowledge = root / "knowledge"
    documents = {root / name for name in REQUIRED if (root / name).is_file()}
    documents.update(path for path in knowledge.rglob("*.md") if not is_history(path, knowledge))
    routes: dict[Path, set[Path]] = {}
    for document in sorted(documents):
        source = document.relative_to(root).as_posix()
        routes[document] = set()
        for link in links(document.read_text(encoding="utf-8")):
            url = urlsplit(link)
            if url.scheme or url.netloc:
                continue
            target = (document.parent / unquote(url.path)).resolve() if url.path else document
            if not target.is_relative_to(root):
                errors.append(f"{source}: link outside repository: {link}")
                continue
            routes[document].add(target)
            if not target.exists():
                errors.append(f"{source}: missing target: {link}")
            elif (
                url.fragment
                and target.is_file()
                and target.suffix.lower() == ".md"
                and unquote(url.fragment) not in anchors(target.read_text(encoding="utf-8"))
            ):
                errors.append(f"{source}: missing heading #{url.fragment}: {link}")

    for source, target in (
        ("AGENTS.md", "knowledge/governance/agent-entrypoint.md"),
        ("knowledge/governance/agent-entrypoint.md", "knowledge/INDEX.md"),
    ):
        if root / target not in routes.get(root / source, set()):
            errors.append(f"{source} must link to {target}")
    claude_routes = routes.get(root / "CLAUDE.md", set())
    if not claude_routes.intersection(
        {root / "AGENTS.md", root / "knowledge/governance/agent-entrypoint.md"}
    ):
        errors.append("CLAUDE.md must link to AGENTS.md or the canonical agent entrypoint")

    index = knowledge / "INDEX.md"
    indexed = routes.get(index, set())
    for document in sorted(documents):
        if document.is_relative_to(knowledge) and document != index:
            if document.is_relative_to(knowledge / "plans"):
                continue
            if document not in indexed:
                errors.append(f"not indexed: {document.relative_to(root).as_posix()}")
    return errors


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", type=Path, default=Path(__file__).resolve().parents[1])
    args = parser.parse_args()
    errors = validate(args.root)
    if errors:
        print(
            "Knowledge navigation failed:\n" + "\n".join(f"- {error}" for error in errors),
            file=sys.stderr,
        )
        return 1
    print("Knowledge navigation passed.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
