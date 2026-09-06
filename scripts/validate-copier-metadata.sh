#!/usr/bin/env bash
# Verify that Copier persists the metadata required for `copier update`.
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
vcs_ref="${1:-HEAD}"
scratch_dir="$(mktemp -d)"
destination="$scratch_dir/rendered-service"

cleanup() {
  rm -rf "$scratch_dir"
}
trap cleanup EXIT

uvx --from copier==9.18.1 copier copy --defaults --trust \
  --vcs-ref "$vcs_ref" "$repo_root" "$destination"

answers_file="$destination/.copier-answers.yml"
for key in _src_path _commit project_name project_slug; do
  if ! grep -Eq "^${key}: .+" "$answers_file"; then
    printf 'Missing non-empty %s in %s\n' "$key" "$answers_file" >&2
    exit 1
  fi
done

printf 'Copier metadata validation passed for %s.\n' "$vcs_ref"
