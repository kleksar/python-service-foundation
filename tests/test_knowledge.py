"""Regression checks for the supported knowledge-navigation Markdown subset."""

import subprocess
import sys
from pathlib import Path

import pytest

ROOT = Path(__file__).resolve().parents[1]
CHECKER = ROOT / "scripts" / "check_knowledge.py"


def write_project(root: Path) -> Path:
    owner = root / "knowledge" / "governance" / "agent-entrypoint.md"
    owner.parent.mkdir(parents=True)
    owner.write_text("# Entrypoint\n\n[Knowledge](../INDEX.md)\n", encoding="utf-8")
    (root / "knowledge" / "INDEX.md").write_text(
        "# Knowledge\n\n[Entrypoint](governance/agent-entrypoint.md)\n", encoding="utf-8"
    )
    (root / "AGENTS.md").write_text(
        "[Start](knowledge/governance/agent-entrypoint.md)\n", encoding="utf-8"
    )
    (root / "CLAUDE.md").write_text("[Instructions](AGENTS.md)\n", encoding="utf-8")
    (root / "README.md").write_text(
        "# Project\n\n[Knowledge](knowledge/INDEX.md)\n", encoding="utf-8"
    )
    return owner


def run_check(root: Path) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        [sys.executable, str(CHECKER), "--root", str(root)],
        capture_output=True,
        text=True,
        check=False,
    )


def test_repository_knowledge_navigation() -> None:
    result = run_check(ROOT)
    assert result.returncode == 0, result.stderr


def test_valid_navigation(tmp_path: Path) -> None:
    write_project(tmp_path)
    result = run_check(tmp_path)
    assert result.returncode == 0, result.stderr
    assert result.stdout == "Knowledge navigation passed.\n"


@pytest.mark.parametrize("filename", ["AGENTS.md", "CLAUDE.md", "knowledge/INDEX.md"])
def test_missing_entry_document(tmp_path: Path, filename: str) -> None:
    write_project(tmp_path)
    (tmp_path / filename).unlink()
    result = run_check(tmp_path)
    assert result.returncode == 1
    assert f"missing {filename}" in result.stderr


@pytest.mark.parametrize(
    "filename", ["README.md", "CLAUDE.md", "knowledge/governance/agent-entrypoint.md"]
)
def test_broken_link_in_any_current_document(tmp_path: Path, filename: str) -> None:
    write_project(tmp_path)
    document = tmp_path / filename
    document.write_text(document.read_text() + "\n[Broken](missing.md)\n", encoding="utf-8")
    result = run_check(tmp_path)
    assert result.returncode == 1
    assert filename in result.stderr
    assert "missing target" in result.stderr


def test_unindexed_canonical_document(tmp_path: Path) -> None:
    write_project(tmp_path)
    (tmp_path / "knowledge" / "new.md").write_text("# New contract\n", encoding="utf-8")
    result = run_check(tmp_path)
    assert result.returncode == 1
    assert "not indexed: knowledge/new.md" in result.stderr


def test_missing_required_navigation_edge(tmp_path: Path) -> None:
    write_project(tmp_path)
    (tmp_path / "AGENTS.md").write_text("# No route\n", encoding="utf-8")
    result = run_check(tmp_path)
    assert result.returncode == 1
    assert "AGENTS.md must link to knowledge/governance/agent-entrypoint.md" in result.stderr


def test_heading_anchors_and_duplicate_headings(tmp_path: Path) -> None:
    owner = write_project(tmp_path)
    owner.write_text(
        owner.read_text()
        + "\n## Using `repo.py`!\n## Using `repo.py`!\n"
        + "\n[First](#using-repopy) [Second](#using-repopy-1)\n"
        + "[Across files](../INDEX.md#knowledge)\n",
        encoding="utf-8",
    )
    result = run_check(tmp_path)
    assert result.returncode == 0, result.stderr


def test_broken_anchor(tmp_path: Path) -> None:
    owner = write_project(tmp_path)
    owner.write_text(owner.read_text() + "\n[Wrong](../INDEX.md#not-present)\n", encoding="utf-8")
    result = run_check(tmp_path)
    assert result.returncode == 1
    assert "missing heading #not-present" in result.stderr


def test_samples_and_external_links_are_not_local_navigation(tmp_path: Path) -> None:
    owner = write_project(tmp_path)
    owner.write_text(
        owner.read_text()
        + "\n````markdown\n[Example](missing.md)\n```\n[Still code](absent.md)\n````\n"
        + "~~~\n[Sample](missing.md)\n~~~\n"
        + "`[Inline sample](absent.md)`\n"
        + "<!-- [Old link](gone.md) -->\n"
        + "[Docs](https://example.org/missing.md#anything) [Mail](mailto:a@example.org)\n",
        encoding="utf-8",
    )
    result = run_check(tmp_path)
    assert result.returncode == 0, result.stderr


def test_encoded_paths_and_link_titles(tmp_path: Path) -> None:
    owner = write_project(tmp_path)
    target = tmp_path / "guide notes.md"
    target.write_text("# Notes\n", encoding="utf-8")
    owner.write_text(
        owner.read_text() + '\n[Guide](../../guide%20notes.md#notes "A title")\n', encoding="utf-8"
    )
    result = run_check(tmp_path)
    assert result.returncode == 0, result.stderr


def test_local_links_cannot_escape_repository(tmp_path: Path) -> None:
    write_project(tmp_path)
    (tmp_path / "README.md").write_text("[External file](../outside.md)\n", encoding="utf-8")
    result = run_check(tmp_path)
    assert result.returncode == 1
    assert "outside repository" in result.stderr


def test_history_is_not_required_in_current_index(tmp_path: Path) -> None:
    write_project(tmp_path)
    for relative in ("archive/specs/old.md", "plans/completed/old.md", "plans/abandoned/old.md"):
        historical = tmp_path / "knowledge" / relative
        historical.parent.mkdir(parents=True, exist_ok=True)
        historical.write_text(
            "# History\n[Historical path](no-longer-exists.md)\n", encoding="utf-8"
        )
    result = run_check(tmp_path)
    assert result.returncode == 0, result.stderr


def test_active_plan_links_are_checked_but_plan_need_not_be_indexed(tmp_path: Path) -> None:
    write_project(tmp_path)
    plan = tmp_path / "knowledge" / "plans" / "active" / "work.md"
    plan.parent.mkdir(parents=True)
    plan.write_text(
        "# Work\n[Requirement](../../governance/agent-entrypoint.md)\n", encoding="utf-8"
    )
    assert run_check(tmp_path).returncode == 0
    plan.write_text("# Work\n[Requirement](missing.md)\n", encoding="utf-8")
    result = run_check(tmp_path)
    assert result.returncode == 1
    assert "missing target" in result.stderr
