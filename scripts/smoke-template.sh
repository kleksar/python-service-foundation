#!/usr/bin/env bash
# Render both supported profiles and verify their generated quality gates.
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
scratch_dir="$(mktemp -d)"
trap 'rm -rf "$scratch_dir"' EXIT

render_and_check() {
  local profile="$1"
  local use_postgres="$2"
  local destination="$scratch_dir/$profile"

  uvx --from copier==9.18.1 copier copy --defaults --trust --vcs-ref=HEAD \
    --data project_name="$profile service" \
    --data project_slug="${profile}_service" \
    --data use_postgres="$use_postgres" \
    "$repo_root" "$destination"

  (
    cd "$destination"
    uv sync --all-groups
    uv run ruff check .
    uv run ruff format --check .
    uv run pyright
    uv run pytest
    if command -v docker >/dev/null 2>&1 && docker compose version >/dev/null 2>&1; then
      docker compose -f compose.yaml config >/dev/null
    fi
  )
}

render_and_check postgres true
render_and_check no_postgres false
printf 'Copier profile smoke validation passed.\n'
