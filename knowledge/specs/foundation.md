# Foundation contract

Status: current

## Purpose and owner

Python Service Foundation is a directly maintainable Python seed with a rich engineering knowledge base. Its owner maintains one installable project, not a matrix of generated applications. A new client project receives ordinary files and becomes independently owned.

The foundation is intended to reduce repeated engineering decisions across backend projects. It does not promise compatibility with every Python library, production readiness or a complete backend runtime before a feature has been selected.

## Executable baseline

The seed provides:

- one supported Python 3.14 interpreter line, pinned for development and CI;
- a standard `src/app/` installable package with import-safe initialization;
- `pyproject.toml` and a committed `uv.lock` for reproducible dependency resolution;
- Ruff formatting/linting, strict Pyrefly and pytest as development tooling;
- direct package and local knowledge-navigation checks;
- a thin Just command facade and CI using the same checks;
- portable agent entrypoints and canonical knowledge.

The baseline has **no runtime dependencies or technology integrations**. There is no demo application, health process, configuration model, error hierarchy, repo/service scaffold, database, queue or container runtime to keep unused. Empty future runtime and test-level directories are not part of the contract.

`src/app/__init__.py` may be imported after installation without external services, environment configuration or network access. The package is the real artifact; passing tests by adding `src` to `PYTHONPATH` is not sufficient proof that a built distribution works.

There is no Jinja/Copier layer, generator profile, module loader or generated metadata file. GitHub's template-copy feature, if used, is only file delivery and does not reintroduce a rendering mechanism.

## Knowledge baseline

[The index](../INDEX.md) discovers all current owners. [Architecture](../architecture/system.md) defines feature-oriented growth; conventions and patterns define implementation discipline; capability recipes define conditional integration guidance.

A capability document does not assert that the capability is installed or verified in this seed. Adding a feature introduces only the dependencies, production code, configuration and tests it actually consumes. No separately testable prerequisite platform is added merely for future usefulness.

[Development](../governance/development.md) governs specification-driven behavior changes and TDD. [Document lifecycle](../governance/document-lifecycle.md) separates current requirements, disposable plans and history. A functioning clone must not depend on personal agent memory, user-scoped skills, a specific model roster or absolute local filesystem paths.

## Verification guarantees

The baseline checks are:

```sh
uv sync --locked
uv run ruff format --check .
uv run ruff check .
uv run pyrefly check
uv run pytest
uv run python scripts/check_knowledge.py
uv run python scripts/check_package.py
```

`just check` is the combined local gate; `just docs-check` and `just package-check` expose the focused document/package checks. The package check builds and verifies installation/import outside the working source directory. CI runs the equivalent baseline rather than rendering profiles or launching unused infrastructure.

Local knowledge checks cover their declared Markdown link/heading-anchor syntax and entrypoint navigation. They do not prove semantic canonical ownership, correctness of every recipe, external URL availability or runtime behavior of integrations that do not exist. Changes to the checker need focused regression tests for its supported syntax, not a claim to parse all Markdown.

A clean copy must resolve from the lockfile and pass the baseline without Postgres, Redis, Docker, private dotenv files or a running application server. No passing seed gate is described as evidence for future migration, worker, network or deployment guarantees. Those checks appear with the capability implementation in its consuming project.

## Creating and growing an independent project

Copy the repository and adjust distribution metadata, README and project purpose through ordinary edits. The import package may remain `app`; renaming all Python imports is not a startup requirement. If distribution metadata changes, update the lockfile as needed before using a locked install.

The first business request establishes a specification and its necessary capabilities. Implement a useful vertical slice using the relevant knowledge, rather than enabling prebuilt optional modules. Runtime and development dependencies can then grow with actual consumers; the absence of dependencies is a **seed baseline**, not a permanent prohibition on client applications.

At that transition, narrow or replace seed-only guarantees in this specification so the current contract truthfully describes the accepted project. Keep applicable engineering owners current. Archive a replaced contract only under document lifecycle; do not leave a contradictory seed specification as active policy in a developed service.

Projects do not depend on a shared foundation runtime package. Updates to copied knowledge/tooling are deliberate changes reviewed against local contracts, not automatic upstream overwrites. Git history can identify provenance; no update engine or permanent synchronization framework is required.

## Non-goals and boundary

Authentication, domain models, public API/error envelopes, persistent schema, background delivery, deployment credentials and operating topology belong to features that introduce them. Their absence from the empty seed is deliberate. A client service must establish its own security and production acceptance before deployment.

This contract replaces the former generated FastAPI/Postgres v0.2 baseline. Prior constructor-specific behavior remains in Git history, not as a competing current owner.
