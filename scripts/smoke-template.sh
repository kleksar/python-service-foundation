#!/usr/bin/env bash
# Render both supported profiles and verify their generated quality gates.
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
scratch_dir="$(mktemp -d)"
template_source="$scratch_dir/template-source"
mkdir -p "$template_source"
git -C "$repo_root" archive --format=tar HEAD | tar -xf - -C "$template_source"
trap 'rm -rf "$scratch_dir"' EXIT

render_and_check() {
  local profile="$1"
  local use_postgres="$2"
  local destination="$scratch_dir/$profile"

  uvx --from copier==9.18.1 copier copy --defaults --trust \
    --data project_name="$profile service" \
    --data project_slug="${profile}_service" \
    --data use_postgres="$use_postgres" \
    "$template_source" "$destination"

  (
    cd "$destination"
    uv sync --all-groups
    "$repo_root/scripts/assert-rendered-profile.sh" \
      "$destination" "$use_postgres" "${profile}_service"
    uv run ruff check .
    uv run ruff format --check .
    uv run pyright
    uv run pytest
    if [[ "$use_postgres" == "true" ]]; then
      uv run alembic heads
      uv run alembic upgrade head --sql >/dev/null
    fi
    if command -v docker >/dev/null 2>&1 && docker compose version >/dev/null 2>&1; then
      docker compose -f compose.yaml config >/dev/null
    fi
  )
}

render_and_check postgres true
render_and_check minimal false
printf 'Copier profile smoke validation passed.\n'
