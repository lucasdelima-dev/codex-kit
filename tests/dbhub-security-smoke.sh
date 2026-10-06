#!/usr/bin/env bash
set -e

PROJECT="$(mktemp -d)"
trap 'rm -rf "$PROJECT"' EXIT

git -C "$PROJECT" init -q

./bin/bootstrap-project "$PROJECT" --dbhub

DB_FILE="$PROJECT/.codex-local/dbhub-smoke.sqlite"
touch "$DB_FILE"

export CODEX_PROJECT_ROOT="$PROJECT"
export DBHUB_DSN="sqlite://$DB_FILE"

CONFIG="$PROJECT/config/mcporter.json"

if grep -q '"dbhub"' "$HOME/.mcporter/mcporter.json"; then
  echo "DBHub vazou para configuração global" >&2
  exit 1
fi

git -C "$PROJECT" check-ignore -q \
  "$PROJECT/.codex-local/dbhub.toml"

git -C "$PROJECT" check-ignore -q \
  "$PROJECT/config/mcporter.json"

if grep -RFq \
  "$DBHUB_DSN" \
  "$PROJECT/.codex-local/dbhub.toml" \
  "$CONFIG"
then
  echo "DBHUB_DSN foi persistido" >&2
  exit 1
fi

READ_OUT="$(
  mcporter call \
    'dbhub.execute_sql(sql: "SELECT 1 AS ok")' \
    --config "$CONFIG"
)"

printf '%s\n' "$READ_OUT"

printf '%s\n' "$READ_OUT" |
  grep -q '"success": true'

printf '%s\n' "$READ_OUT" |
  grep -q '"ok": 1'

HASH_BEFORE="$(
  python3 - "$DB_FILE" <<'PYHASH'
import hashlib
import sys

with open(sys.argv[1], "rb") as f:
    print(hashlib.sha256(f.read()).hexdigest())
PYHASH
)"

set +e

WITH_OUT="$(
  mcporter call \
    'dbhub.execute_sql(sql: "WITH payload(marker) AS (SELECT 1) INSERT INTO forbidden(marker) SELECT marker FROM payload")' \
    --config "$CONFIG" \
    2>&1
)"

WITH_STATUS=$?

set -e

printf '%s\n' "$WITH_OUT"

test "$WITH_STATUS" -ne 0

printf '%s\n' "$WITH_OUT" |
  grep -q 'READONLY_VIOLATION'

set +e

PRAGMA_OUT="$(
  mcporter call \
    'dbhub.execute_sql(sql: "PRAGMA user_version = 4242")' \
    --config "$CONFIG" \
    2>&1
)"

PRAGMA_STATUS=$?

set -e

printf '%s\n' "$PRAGMA_OUT"

test "$PRAGMA_STATUS" -ne 0

printf '%s\n' "$PRAGMA_OUT" |
  grep -q 'READONLY_VIOLATION'

HASH_AFTER="$(
  python3 - "$DB_FILE" <<'PYHASH'
import hashlib
import sys

with open(sys.argv[1], "rb") as f:
    print(hashlib.sha256(f.read()).hexdigest())
PYHASH
)"

if [ "$HASH_AFTER" != "$HASH_BEFORE" ]; then
  echo "DBHub alterou o arquivo SQLite em modo readonly" >&2
  exit 1
fi

test -z "$(git -C "$PROJECT" status --short)"

echo "✅ DBHub Unix security smoke passou"
