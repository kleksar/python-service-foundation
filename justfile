default:
    @just --list

bootstrap:
    uv sync --locked

format:
    uv run ruff format .

format-check:
    uv run ruff format --check .

lint:
    uv run ruff check .

typecheck:
    uv run pyrefly check

test:
    uv run pytest

docs-check:
    uv run python scripts/check_knowledge.py

package-check:
    uv run python scripts/check_package.py

build:
    uv build --no-build-isolation

check: bootstrap format-check lint typecheck test package-check
