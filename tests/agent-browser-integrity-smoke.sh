#!/usr/bin/env bash
set -euo pipefail

KIT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

. "$KIT/manifests/tools.env"
. "$KIT/lib/machine.sh"

PREFIX="$HOME/.local"
NODE="$PREFIX/opt/node24/bin/node"

case "$(uname -s):$(uname -m)" in
  Linux:x86_64)
    ASSET="agent-browser-linux-x64"
    EXPECTED="$AGENT_BROWSER_SHA256_LINUX_X64"
    ;;
  Linux:aarch64|Linux:arm64)
    ASSET="agent-browser-linux-arm64"
    EXPECTED="$AGENT_BROWSER_SHA256_LINUX_ARM64"
    ;;
  Darwin:x86_64)
    ASSET="agent-browser-darwin-x64"
    EXPECTED="$AGENT_BROWSER_SHA256_MACOS_X64"
    ;;
  Darwin:arm64|Darwin:aarch64)
    ASSET="agent-browser-darwin-arm64"
    EXPECTED="$AGENT_BROWSER_SHA256_MACOS_ARM64"
    ;;
  *)
    echo "Plataforma não suportada pelo smoke" >&2
    exit 2
    ;;
esac

ROOT="$PREFIX/lib/node_modules/agent-browser"
BINARY="$ROOT/bin/$ASSET"
WRAPPER="$ROOT/bin/agent-browser.js"

echo "=== Binário instalado ==="

test -f "$BINARY"
test -f "$WRAPPER"
test -x "$NODE"

ACTUAL="$(agent_browser_sha256 "$BINARY")"
test "$ACTUAL" = "$EXPECTED"

echo "✅ SHA-256 oficial confirmado"

echo "=== Wrapper JavaScript ==="

OUTPUT="$("$NODE" "$WRAPPER" --version 2>&1)"

if ! grep -Fq "$AGENT_BROWSER_VERSION" <<< "$OUTPUT"; then
  echo "Versão inesperada: $OUTPUT" >&2
  exit 1
fi

echo "✅ Wrapper funcional: $OUTPUT"

echo "=== Testes isolados do instalador ==="

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

mkdir -p "$TMP/mock-bin"

export MOCK_ROOT="$TMP/prefix/lib/node_modules/agent-browser"
export MOCK_PAYLOAD="$TMP/payload"
export MOCK_NPM_ARGS="$TMP/npm-args"

printf '#!/bin/sh\necho fixture\n' > "$MOCK_PAYLOAD"
GOOD_SHA="$(agent_browser_sha256 "$MOCK_PAYLOAD")"

cat > "$TMP/mock-npm" <<'MOCK'
#!/usr/bin/env bash
set -euo pipefail

printf '%s\n' "$*" > "$MOCK_NPM_ARGS"

case " $* " in
  *" --ignore-scripts "*) ;;
  *)
    echo "ERRO: npm sem --ignore-scripts" >&2
    exit 4
    ;;
esac

mkdir -p "$MOCK_ROOT/bin"

printf '{"version":"0.38.1"}\n' \
  > "$MOCK_ROOT/package.json"

printf '// wrapper simulado\n' \
  > "$MOCK_ROOT/bin/agent-browser.js"
MOCK

cat > "$TMP/mock-bin/curl" <<'MOCK'
#!/usr/bin/env bash
set -euo pipefail

DEST=""

while [ "$#" -gt 0 ]; do
  if [ "$1" = "-o" ]; then
    DEST="$2"
    shift 2
  else
    shift
  fi
done

test -n "$DEST"
cp "$MOCK_PAYLOAD" "$DEST"
MOCK

chmod +x "$TMP/mock-npm" "$TMP/mock-bin/curl"

PREFIX="$TMP/prefix"
NPM="$TMP/mock-npm"
export PATH="$TMP/mock-bin:$PATH"

case "$ASSET" in
  agent-browser-linux-*)
    PLATFORM_KEY="linux"
    ;;
  agent-browser-darwin-*)
    PLATFORM_KEY="darwin"
    ;;
esac

ARCH_KEY="${ASSET##*-}"
TARGET="$MOCK_ROOT/bin/$ASSET"

ensure_agent_browser \
  "$PLATFORM_KEY" "$ARCH_KEY" "$GOOD_SHA"

test "$(agent_browser_sha256 "$TARGET")" = "$GOOD_SHA"
grep -Fq -- '--ignore-scripts' "$MOCK_NPM_ARGS"

echo "✅ Instalação simulada sem postinstall"

echo "=== Rejeição de artefato adulterado ==="

printf 'binario-local-preservar\n' > "$TARGET"
printf 'download-adulterado\n' > "$MOCK_PAYLOAD"

if ensure_agent_browser \
  "$PLATFORM_KEY" "$ARCH_KEY" "$GOOD_SHA"; then
  echo "ERRO: download adulterado foi aceito" >&2
  exit 1
fi

test "$(cat "$TARGET")" = "binario-local-preservar"

echo "✅ Hash incorreto rejeitado"
echo "✅ Executável anterior preservado"
echo "✅ Agent-browser integrity smoke passou"
