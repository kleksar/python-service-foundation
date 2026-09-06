#!/usr/bin/env bash
# Render the PostgreSQL profile and prove readiness during a Compose outage and recovery.
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
scratch_dir="$(mktemp -d)"
template_source="$scratch_dir/template-source"
destination="$scratch_dir/readiness-service"
project_name="foundation-readiness-${RANDOM}-${RANDOM}"
cleanup() {
  if [[ -d "$destination" ]]; then
    docker compose -p "$project_name" -f "$destination/compose.yaml" down --volumes --remove-orphans >/dev/null 2>&1 || true
  fi
  rm -rf "$scratch_dir"
}
trap cleanup EXIT

require_command() {
  command -v "$1" >/dev/null 2>&1 || { printf 'Missing required command: %s\n' "$1" >&2; exit 2; }
}
require_command docker
require_command curl
require_command python3
require_command uvx
docker compose version >/dev/null

mkdir -p "$template_source"
git -C "$repo_root" archive --format=tar HEAD | tar -xf - -C "$template_source"
uvx --from copier==9.18.1 copier copy --defaults --trust \
  --data project_name="Readiness outage service" \
  --data project_slug="readiness_service" \
  --data use_postgres=true \
  "$template_source" "$destination"

# Use random host ports so a host's default 8000/5432 bindings are not classified as template failures.
allocate_port() {
  python3 - <<'PY'
import socket
with socket.socket() as sock:
    sock.bind(("127.0.0.1", 0))
    print(sock.getsockname()[1])
PY
}
app_port="${READINESS_APP_HOST_PORT:-$(allocate_port)}"
postgres_port="${READINESS_POSTGRES_HOST_PORT:-$(allocate_port)}"
if [[ ! "$app_port" =~ ^[0-9]+$ || ! "$postgres_port" =~ ^[0-9]+$ ]] || \
  (( app_port < 1 || app_port > 65535 || postgres_port < 1 || postgres_port > 65535 )); then
  printf 'READINESS_APP_HOST_PORT and READINESS_POSTGRES_HOST_PORT must be valid ports.\n' >&2
  exit 2
fi
if [[ "$app_port" == "$postgres_port" ]]; then
  printf 'READINESS_APP_HOST_PORT and READINESS_POSTGRES_HOST_PORT must differ.\n' >&2
  exit 2
fi
python3 - "$destination/compose.yaml" "$app_port" "$postgres_port" <<'PY'
from pathlib import Path
import sys

path = Path(sys.argv[1])
text = path.read_text()
text = text.replace('      - "8000:8000"', f'      - "127.0.0.1:{sys.argv[2]}:8000"')
text = text.replace('      - "5432:5432"', f'      - "127.0.0.1:{sys.argv[3]}:5432"')
path.write_text(text)
PY

status_code() {
  curl --silent --output /dev/null --write-out '%{http_code}' "http://127.0.0.1:${app_port}$1"
}
wait_for_status() {
  local endpoint="$1" expected="$2"
  for _ in $(seq 1 60); do
    if [[ "$(status_code "$endpoint" || true)" == "$expected" ]]; then
      return 0
    fi
    sleep 1
  done
  printf 'Timed out waiting for %s to return HTTP %s\n' "$endpoint" "$expected" >&2
  return 1
}

docker compose -p "$project_name" -f "$destination/compose.yaml" up --build --detach
wait_for_status /health/ready 200
docker compose -p "$project_name" -f "$destination/compose.yaml" stop postgres
wait_for_status /health/ready 503
[[ "$(status_code /health/live)" == 200 ]]
docker compose -p "$project_name" -f "$destination/compose.yaml" start postgres
wait_for_status /health/ready 200
printf 'Compose readiness outage/recovery acceptance passed.\n'
