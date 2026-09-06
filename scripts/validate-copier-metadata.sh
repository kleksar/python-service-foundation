#!/usr/bin/env bash
# Verify that Copier persists the metadata required for `copier update`.
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
vcs_ref="${1:-HEAD}"
scratch_dir="$(mktemp -d)"
template_source="$scratch_dir/template-source"
destination="$scratch_dir/rendered-service"

git clone --quiet --no-local "$repo_root" "$template_source"
git -C "$template_source" checkout --quiet "$vcs_ref"

cleanup() {
  rm -rf "$scratch_dir"
}
trap cleanup EXIT

uvx --from copier==9.18.1 copier copy --defaults --trust \
  --vcs-ref "$vcs_ref" "$template_source" "$destination"

answers_file="$destination/.copier-answers.yml"
for key in _src_path _commit project_name project_slug; do
  if ! grep -Eq "^${key}: .+" "$answers_file"; then
    printf 'Missing non-empty %s in %s\n' "$key" "$answers_file" >&2
    exit 1
  fi
done

printf 'Copier metadata validation passed for %s.\n' "$vcs_ref"
