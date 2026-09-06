#!/usr/bin/env bash
# Verify Copier metadata and profile-safe updates from the latest release to a candidate revision.
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
vcs_ref="${1:-HEAD}"
base_ref="${2:-v0.2.0}"
scratch_dir="$(mktemp -d)"
template_source="$scratch_dir/template-source"
candidate_commit="$(git -C "$repo_root" rev-parse "${vcs_ref}^{commit}")"
base_commit="$(git -C "$repo_root" rev-parse "${base_ref}^{commit}")"

cleanup() {
  rm -rf "$scratch_dir"
}
trap cleanup EXIT

git clone --quiet --no-local "$repo_root" "$template_source"
git -C "$template_source" cat-file -e "${candidate_commit}^{commit}"
git -C "$template_source" cat-file -e "${base_commit}^{commit}"

validate_metadata() {
  local destination="$1"
  local expected_commit="$2"
  local answers_file="$destination/.copier-answers.yml"
  local recorded_ref
  local recorded_commit

  for key in _src_path _commit project_name project_slug use_postgres; do
    if ! grep -Eq "^${key}: .+" "$answers_file"; then
      printf 'Missing non-empty %s in %s\n' "$key" "$answers_file" >&2
      exit 1
    fi
  done

  recorded_ref="$(sed -n 's/^_commit: //p' "$answers_file")"
  recorded_commit="$(git -C "$template_source" rev-parse "${recorded_ref}^{commit}")"
  if [[ "$recorded_commit" != "$expected_commit" ]]; then
    printf 'Copier metadata points to %s, expected %s\n' \
      "$recorded_commit" "$expected_commit" >&2
    exit 1
  fi
}

assert_no_update_conflicts() {
  local destination="$1"

  if find "$destination" -type f -name '*.rej' -print -quit | grep -q .; then
    printf 'Copier update produced rejection files in %s\n' "$destination" >&2
    exit 1
  fi
  if git -C "$destination" grep -nE '^(<<<<<<<|=======|>>>>>>>)' -- .; then
    printf 'Copier update produced conflict markers in %s\n' "$destination" >&2
    exit 1
  fi
}

render_candidate() {
  local profile="$1"
  local use_postgres="$2"
  local project_slug="${profile}_service"
  local destination="$scratch_dir/copy-$profile"

  uvx --from copier==9.18.1 copier copy --defaults --trust \
    --vcs-ref "$candidate_commit" \
    --data project_name="$profile service" \
    --data project_slug="$project_slug" \
    --data use_postgres="$use_postgres" \
    "$template_source" "$destination"

  validate_metadata "$destination" "$candidate_commit"
  "$repo_root/scripts/assert-rendered-profile.sh" \
    "$destination" "$use_postgres" "$project_slug"
}

update_from_release() {
  local profile="$1"
  local use_postgres="$2"
  local project_slug="${profile}_service"
  local destination="$scratch_dir/update-$profile"

  uvx --from copier==9.18.1 copier copy --defaults --trust \
    --vcs-ref "$base_ref" \
    --data project_name="$profile service" \
    --data project_slug="$project_slug" \
    --data use_postgres="$use_postgres" \
    "$template_source" "$destination"

  validate_metadata "$destination" "$base_commit"
  git -C "$destination" init --quiet
  git -C "$destination" config user.name 'Copier Validation'
  git -C "$destination" config user.email 'copier-validation@example.invalid'
  git -C "$destination" add .
  git -C "$destination" commit --quiet -m 'chore: capture release render'

  (
    cd "$destination"
    uvx --from copier==9.18.1 copier update --defaults --trust \
      --vcs-ref "$candidate_commit"
  )

  validate_metadata "$destination" "$candidate_commit"
  assert_no_update_conflicts "$destination"
  "$repo_root/scripts/assert-rendered-profile.sh" \
    "$destination" "$use_postgres" "$project_slug"
}

render_candidate postgres true
render_candidate minimal false
update_from_release postgres true
update_from_release minimal false
printf 'Copier metadata and update validation passed for %s from %s.\n' \
  "$candidate_commit" "$base_ref"
