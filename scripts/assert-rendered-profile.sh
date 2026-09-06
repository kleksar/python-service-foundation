#!/usr/bin/env bash
# Assert the generated profile contains exactly the supported database boundary.
set -euo pipefail

if [[ "$#" -ne 3 ]]; then
  printf 'Usage: %s DESTINATION USE_POSTGRES PROJECT_SLUG\n' "$0" >&2
  exit 2
fi

destination="$(cd "$1" && pwd)"
use_postgres="$2"
project_slug="$3"

database_paths=(
  "alembic"
  "alembic.ini"
  "env/postgres.example"
  "src/$project_slug/database.py"
)

if [[ "$use_postgres" == "true" ]]; then
  required_database_files=(
    "alembic/env.py"
    "alembic/script.py.mako"
    "alembic/versions/0001_initial.py"
    "alembic.ini"
    "env/postgres.example"
    "src/$project_slug/database.py"
  )
  for relative_path in "${required_database_files[@]}"; do
    if [[ ! -f "$destination/$relative_path" ]]; then
      printf 'Missing PostgreSQL profile artifact: %s\n' "$relative_path" >&2
      exit 1
    fi
  done

  grep -Fq 'sqlalchemy[asyncio]' "$destination/pyproject.toml"
  grep -Fq 'asyncpg' "$destination/pyproject.toml"
  grep -Fq 'alembic' "$destination/pyproject.toml"
  grep -Fq 'postgres' "$destination/compose.yaml"
  grep -Fq 'DATABASE_URL=' "$destination/env/app.example"
  printf 'PostgreSQL profile artifact validation passed.\n'
elif [[ "$use_postgres" == "false" ]]; then
  unexpected_paths=()
  for relative_path in "${database_paths[@]}"; do
    if [[ -e "$destination/$relative_path" ]]; then
      unexpected_paths+=("$relative_path")
    fi
  done
  if (( ${#unexpected_paths[@]} > 0 )); then
    printf 'Unexpected PostgreSQL profile artifacts:\n' >&2
    printf '  %s\n' "${unexpected_paths[@]}" >&2
    exit 1
  fi

  searchable_files=()
  for runtime_path in pyproject.toml compose.yaml env src tests uv.lock; do
    if [[ -f "$destination/$runtime_path" ]]; then
      searchable_files+=("$destination/$runtime_path")
    elif [[ -d "$destination/$runtime_path" ]]; then
      while IFS= read -r -d '' generated_file; do
        searchable_files+=("$generated_file")
      done < <(find "$destination/$runtime_path" -type f -print0)
    fi
  done
  if (( ${#searchable_files[@]} > 0 )) && \
    grep -HnEi 'alembic|asyncpg|sqlalchemy|postgres|database_url|check_database' \
      "${searchable_files[@]}"; then
    printf 'Unexpected PostgreSQL dependency or runtime reference in minimal profile.\n' >&2
    exit 1
  fi
  printf 'Minimal profile database-artifact validation passed.\n'
else
  printf 'USE_POSTGRES must be true or false, got: %s\n' "$use_postgres" >&2
  exit 2
fi
