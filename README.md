# Python Service Foundation

A deliberately minimal Copier template for a runnable Python 3.13+ FastAPI service. It supplies a small vertical slice and leaves product-domain, deployment, credential, and operations ownership with the generated service team. It does not claim to be deploy ready.

## Profiles

The baseline is always FastAPI, Uvicorn, structured standard-library logging, typed Pydantic Settings, liveness and readiness endpoints, uv tooling, tests, and quality checks. `use_postgres` is a first-party Copier boolean that defaults to `true`. When enabled it adds async SQLAlchemy, asyncpg, Alembic, a PostgreSQL Compose service, and a dependency-aware readiness check. When disabled, generated code has no database imports, dependencies, or runtime requirement.

The template intentionally excludes Redis, Taskiq, Sentry, MCP, authentication, and domain logic.

## Render the template

```bash
uvx --from copier==9.18.1 copier copy . /path/to/new-service
```

Choose a lowercase Python package identifier for `project_slug`. Copier defaults `use_postgres` to `true`; pass `--data use_postgres=false` for the dependency-free profile.

## Validate the template

```bash
scripts/smoke-template.sh
scripts/validate-copier-metadata.sh HEAD
scripts/compose-readiness-outage.sh
```

The smoke script renders both profiles, installs each generated project, runs Ruff, Pyright, and pytest, and validates Compose configuration when Docker Compose is available. It does not require secrets or a running database. `compose-readiness-outage.sh` is an opt-in Docker acceptance that renders the PostgreSQL profile, stops its Compose PostgreSQL service, verifies readiness becomes `503` while liveness stays `200`, then verifies readiness recovers. It allocates temporary host ports, so an unrelated service using the default ports is not treated as a template defect.
