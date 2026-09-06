# Python Service Foundation

A real Python project with a small executable core and a broad, selectively loaded engineering knowledge base. Copy it for a new service, describe the business feature, and implement only the capabilities that feature needs.

The seed has **no runtime dependencies** and no pretend server, database, worker, or demo domain. FastAPI, PostgreSQL, Alembic, Redis, Taskiq and other integrations live as [conditional recipes](knowledge/INDEX.md), not disabled modules. There is no template renderer or project generator.

## Start a project

Use GitHub **Use this template** to create an independent repository, then clone that repository. Alternatively, copy a source archive into a new directory and initialize a new Git repository there. Cloning this foundation directly retains its history; it does not create an independent project automatically.

1. Install [uv](https://docs.astral.sh/uv/getting-started/installation/).
2. Update the distribution name and description in `pyproject.toml` and replace this README with your project's purpose. Keep the neutral `app` Python package unless there is a concrete reason to rename it.
3. Run `uv lock` after changing package metadata and commit the resulting `uv.lock` with the metadata change.
4. Install and verify the project:

```bash
uv sync --locked
uv run ruff format --check .
uv run ruff check .
uv run pyrefly check
uv run pytest
uv run python scripts/check_package.py
```

uv installs the supported Python 3.14 interpreter if needed. A fresh, unchanged copy needs only `uv sync --locked`, not a lockfile update. The lockfile fixes development and build dependencies; feature dependencies are added deliberately with their code.

## Development

[AGENTS.md](AGENTS.md) is the portable AI entrypoint; [CLAUDE.md](CLAUDE.md) points to the same rules. Neither requires a personal agent setup. Start with the [knowledge index](knowledge/INDEX.md) and read only the owners relevant to the task.

- Define durable behavior in a specification, or update its existing owner.
- Use a plan only for dependency ordering, coordination or recovery.
- Change behavior through failing tests, minimal implementation, then refactoring.
- Add runtime code and dependencies only for an actual feature.
- Keep current specifications current after implementation; archive only replaced or withdrawn contracts.

See [development](knowledge/governance/development.md), [document lifecycle](knowledge/governance/document-lifecycle.md), and the [seed contract](knowledge/specs/foundation.md) for the canonical rules. A copied project updates that seed contract as its accepted responsibilities change; it is not permanently forbidden from gaining runtime dependencies.

## Layout

```text
src/app/        Installable application package; feature modules appear on demand
knowledge/      Architecture, conventions, patterns, recipes and current specifications
scripts/        Development-only navigation and built-package checks
tests/          Package and navigation regression tests; feature tests grow here
```

The target runtime structure is feature-oriented, with one `service.py` and one semantic `repo.py` per business module. `schemas.py` and `errors.py` can contain multiple related types. None of those files exists before it has a responsibility. See [module layout](knowledge/architecture/layout.md).

## Commands and checks

The commands above are the direct quality gate used in CI. If [Just](https://just.systems/) is installed, `just check` runs the same gate; Just is optional, uv is not.

| Command | Purpose |
| --- | --- |
| `just bootstrap` | Locked installation |
| `just format` | Apply Ruff formatting |
| `just lint` | Ruff lint checks |
| `just typecheck` | Strict Pyrefly checks |
| `just test` | pytest, including package import and knowledge navigation |
| `just docs-check` | Navigation check alone |
| `just package-check` | Build sdist/wheel and import the installed wheel in an isolated environment |
| `just build` | Build distribution artifacts into `dist/` |

`check_package.py` uses the locked build environment, builds the wheel from the sdist, and installs locked runtime dependencies plus that wheel into a temporary environment. It never imports the wheel through a source-tree `PYTHONPATH`.

The knowledge checker verifies local inline Markdown links, ATX heading anchors, canonical index registration, and agent-entrypoint routes. It skips code examples, HTML comments, remote URLs and historical archive/completed/abandoned documents. Use URL-encoded spaces/parentheses in targets; reference links, HTML anchors and setext headings are outside its deliberately small scope. It does not prove semantic consistency or that an unimplemented capability works.

No Docker daemon, database or credentials are needed for the seed gate. Integration infrastructure and its real boundary-crossing tests are introduced together when a feature requires them.

## Updating copied projects

Each copied project owns its code and contracts. Record its foundation revision if useful, and transfer selected knowledge/tooling improvements by reviewing the diff. There is no runtime dependency on foundation, automatic regeneration, or promise of conflict-free updates to client-specific decisions.
