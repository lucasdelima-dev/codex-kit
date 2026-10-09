#!/usr/bin/env bash
set -euo pipefail

KIT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

A="$TMP/projeto-a"
B="$TMP/projeto-b"

printf '%s\n' '# Instruções originais' > "$TMP/expected-agents"
printf '%s\n' 'node_modules/' > "$TMP/expected-gitignore"

for project in "$A" "$B"; do
  mkdir -p "$project"
  git -C "$project" init -q

  cp "$TMP/expected-agents" "$project/AGENTS.md"
  cp "$TMP/expected-gitignore" "$project/.gitignore"

  git -C "$project" add AGENTS.md .gitignore
  git -C "$project" \
    -c user.name="Codex Kit Smoke" \
    -c user.email="smoke@example.invalid" \
    commit -qm baseline

  git -C "$project" config core.hooksPath "hooks-existentes"
done

# O bootstrap não deve sobrescrever uma função existente.
git -C "$B" config beads.role contributor

export CI=true
export BD_DISABLE_METRICS=1

for project in "$A" "$B"; do
  echo "=== Bootstrap: $(basename "$project") ==="
  "$KIT/bin/bootstrap-project" "$project" --beads

  test -f "$project/.beads/config.yaml"
  grep -Eq '^no-git-ops:[[:space:]]*true' \
    "$project/.beads/config.yaml"

  git -C "$project" check-ignore -q \
    "$project/.beads/config.yaml"

  cmp "$TMP/expected-agents" "$project/AGENTS.md"
  cmp "$TMP/expected-gitignore" "$project/.gitignore"

  test "$(git -C "$project" config --get core.hooksPath)" \
    = "hooks-existentes"

  test -z "$(git -C "$project" status --porcelain)"

  echo "✅ Stealth, Git e arquivos originais preservados"
done

test "$(git -C "$A" config --get beads.role)" = "maintainer"
test "$(git -C "$B" config --get beads.role)" = "contributor"

echo "✅ Funções Git preservadas"

# O segundo projeto foi usado para testar preservação da função.
# Para exercitar criação e atualização, usamos maintainer nos dois.
git -C "$B" config beads.role maintainer

echo "=== Tarefas independentes ==="

ID_A="$(
  cd "$A"
  BEADS_DIR="$A/.beads" bd create --silent \
    "AUDIT-BEADS-ALPHA-ONLY"
)"

ID_B="$(
  cd "$B"
  BEADS_DIR="$B/.beads" bd create --silent \
    "AUDIT-BEADS-BETA-ONLY"
)"

test -n "$ID_A"
test -n "$ID_B"

(
  cd "$A"
  export BEADS_DIR="$A/.beads"

  bd update "$ID_A" --status in_progress >/dev/null
  bd show "$ID_A" --json | grep -q 'AUDIT-BEADS-ALPHA-ONLY'

  if bd list --json | grep -q 'AUDIT-BEADS-BETA-ONLY'; then
    echo "❌ Tarefa do projeto B apareceu no A" >&2
    exit 1
  fi
)

(
  cd "$B"
  export BEADS_DIR="$B/.beads"

  bd update "$ID_B" --status in_progress >/dev/null
  bd show "$ID_B" --json | grep -q 'AUDIT-BEADS-BETA-ONLY'

  if bd list --json | grep -q 'AUDIT-BEADS-ALPHA-ONLY'; then
    echo "❌ Tarefa do projeto A apareceu no B" >&2
    exit 1
  fi
)

for project in "$A" "$B"; do
  test -z "$(git -C "$project" status --porcelain)"
  echo "✅ Git limpo: $(basename "$project")"
done

echo "✅ Beads Unix security smoke passou"
