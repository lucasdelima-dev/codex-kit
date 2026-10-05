#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
KIT="$(cd "$SCRIPT_DIR/../.." && pwd)"

. "$KIT/manifests/tools.env"

PREFIX="$HOME/.local"
BIN="$PREFIX/bin"
OPT="$PREFIX/opt"
SHARE="$PREFIX/share"

NODE_DIR="$OPT/node-v$NODE24_VERSION"
NODE24="$OPT/node24"

mkdir -p "$BIN" "$OPT" "$SHARE"

export PATH="$BIN:$NODE24/bin:$PATH"

. "$KIT/lib/machine.sh"

log "Plataforma"

OS="$(uname -s)"
RAW_ARCH="$(uname -m)"
PLATFORM="${CODEX_PLATFORM:-linux}"
ARCH="${CODEX_ARCH:-$RAW_ARCH}"

case "$ARCH" in
  x86_64)
    NODE_ARCH="x64"
    RTK_TARGET="x86_64-unknown-linux-musl"
    ;;
  aarch64)
    NODE_ARCH="arm64"
    RTK_TARGET="aarch64-unknown-linux-gnu"
    ;;
  *)
    echo "Arquitetura Linux não suportada: $ARCH" >&2
    exit 2
    ;;
esac

echo "    SO:       $OS"
echo "    Plataforma: $PLATFORM"
echo "    ARCH:     $ARCH"

[ "$OS" = "Linux" ] || {
  echo "Adapter Linux executado fora do Linux." >&2
  exit 2
}


log "Dependências básicas"

MISSING=0

for cmd in git curl wget tar unzip rsync jq python3 xz make g++; do
  command -v "$cmd" >/dev/null 2>&1 || MISSING=1
done

if [ "$MISSING" -eq 1 ]; then
  sudo apt-get update
  sudo apt-get install -y \
    git curl wget tar unzip rsync jq \
    python3 xz-utils build-essential ca-certificates
else
  ok "dependências do sistema"
fi


log "Node $NODE24_VERSION"

CURRENT_NODE=""

if [ -x "$NODE_DIR/bin/node" ]; then
  CURRENT_NODE="$("$NODE_DIR/bin/node" --version 2>/dev/null || true)"
fi

if [ "$CURRENT_NODE" != "v$NODE24_VERSION" ]; then
  TMP="$(mktemp -d)"
  ARCHIVE="node-v$NODE24_VERSION-linux-$NODE_ARCH.tar.xz"
  BASE="https://nodejs.org/dist/v$NODE24_VERSION"

  curl -fsSL "$BASE/$ARCHIVE" -o "$TMP/$ARCHIVE"
  curl -fsSL "$BASE/SHASUMS256.txt" -o "$TMP/SHASUMS256.txt"

  grep " $ARCHIVE$" "$TMP/SHASUMS256.txt" > "$TMP/checksum"

  (
    cd "$TMP"
    sha256sum -c checksum
  )

  [ -e "$NODE_DIR" ] && \
    mv "$NODE_DIR" "$NODE_DIR.broken-$(date +%s)"

  tar -xJf "$TMP/$ARCHIVE" -C "$OPT"

  mv \
    "$OPT/node-v$NODE24_VERSION-linux-$NODE_ARCH" \
    "$NODE_DIR"

  rm -rf "$TMP"
fi

ln -sfn "node-v$NODE24_VERSION" "$NODE24"

NODE="$NODE24/bin/node"
NPM="$NODE24/bin/npm"

ok "$("$NODE" --version)"


log "uv $UV_VERSION"

CURRENT_UV="$(uv --version 2>/dev/null | awk '{print $2}' || true)"

if [ "$CURRENT_UV" != "$UV_VERSION" ]; then
  TMP="$(mktemp -d)"

  curl -fsSL \
    "https://astral.sh/uv/$UV_VERSION/install.sh" \
    -o "$TMP/install-uv.sh"

  env \
    UV_INSTALL_DIR="$BIN" \
    UV_NO_MODIFY_PATH=1 \
    sh "$TMP/install-uv.sh"

  rm -rf "$TMP"
fi

UV="$BIN/uv"

ok "$("$UV" --version)"


log "Ferramentas npm"

ensure_npm "@openai/codex" "$CODEX_VERSION"
ensure_npm "@fission-ai/openspec" "$OPENSPEC_VERSION"
ensure_npm "@lzehrung/codegraph" "$CODEGRAPH_VERSION"
ensure_npm "ctx7" "$CTX7_VERSION"
ensure_npm "@beads/bd" "$BEADS_VERSION"
ensure_npm "repomix" "$REPOMIX_VERSION"
ensure_npm "agent-browser" "$AGENT_BROWSER_VERSION"
ensure_npm "@playwright/cli" "$PLAYWRIGHT_CLI_VERSION"
ensure_npm "chrome-devtools-mcp" "$CHROME_DEVTOOLS_VERSION"
ensure_npm "@bytebase/dbhub" "$DBHUB_VERSION"
ensure_npm "ui-ux-pro-max-cli" "$UI_UX_PRO_MAX_VERSION"


log "Ferramentas uv"

ensure_uv_tool "serena-agent" "$SERENA_VERSION"
ensure_uv_tool "semgrep" "$SEMGREP_VERSION"


log "mcporter"

MCPORTER_ROOT="$SHARE/mcporter"
mkdir -p "$MCPORTER_ROOT"

MCP_CURRENT="$(pkg_version \
  "$MCPORTER_ROOT/node_modules/mcporter/package.json" \
  2>/dev/null || true)"

if [ "$MCP_CURRENT" != "$MCPORTER_VERSION" ]; then
  "$NPM" install \
    --prefix "$MCPORTER_ROOT" \
    "mcporter@$MCPORTER_VERSION"
else
  ok "mcporter@$MCPORTER_VERSION"
fi


log "RTK"

RTK_CURRENT="$(rtk --version 2>/dev/null |
  grep -oE '[0-9]+\.[0-9]+\.[0-9]+' |
  head -1 || true)"

if [ "$RTK_CURRENT" != "$RTK_VERSION" ]; then
  TMP="$(mktemp -d)"

  ASSET="rtk-$RTK_TARGET.tar.gz"
  BASE="https://github.com/rtk-ai/rtk/releases/download/v$RTK_VERSION"

  curl -fsSL "$BASE/$ASSET" -o "$TMP/$ASSET"
  curl -fsSL "$BASE/checksums.txt" -o "$TMP/checksums.txt"

  grep "$ASSET$" "$TMP/checksums.txt" > "$TMP/checksum"

  (
    cd "$TMP"
    sha256sum -c checksum
  )

  tar -xzf "$TMP/$ASSET" -C "$TMP"

  RTK_BIN="$(find "$TMP" -type f -name rtk -print -quit)"

  [ -n "$RTK_BIN" ] || {
    echo "Binário RTK não encontrado no release." >&2
    exit 3
  }

  install -m 755 "$RTK_BIN" "$BIN/rtk"

  rm -rf "$TMP"
else
  ok "rtk@$RTK_VERSION"
fi


log "pnpm para OpenDesign"

PNPM="$NODE24/bin/pnpm"
PNPM_CURRENT=""

[ -x "$PNPM" ] && \
  PNPM_CURRENT="$("$PNPM" --version 2>/dev/null || true)"

if [ "$PNPM_CURRENT" != "$PNPM_VERSION" ]; then
  "$NPM" install -g \
    --prefix "$NODE_DIR" \
    "pnpm@$PNPM_VERSION"
else
  ok "pnpm@$PNPM_VERSION"
fi


log "OpenDesign"

OD_ROOT="$SHARE/open-design-$OPENDESIGN_VERSION"
OD_CLI="$OD_ROOT/apps/daemon/dist/cli.js"

if [ ! -d "$OD_ROOT" ]; then
  git clone \
    --depth 1 \
    --branch "$OPENDESIGN_TAG" \
    https://github.com/nexu-io/open-design.git \
    "$OD_ROOT"
fi

if [ ! -f "$OD_CLI" ]; then
  (
    cd "$OD_ROOT"

    export PATH="$NODE24/bin:$PATH"
    export NEXT_TELEMETRY_DISABLED=1

    "$PNPM" install --frozen-lockfile

    "$PNPM" \
      --filter @open-design/daemon \
      build

    NODE_OPTIONS=--max-old-space-size=4096 \
      "$PNPM" \
      --filter @open-design/web \
      build
  )
else
  ok "OpenDesign $OPENDESIGN_VERSION"
fi


log "Wrappers globais"

for wrapper in \
  codex-code \
  chrome-devtools \
  mcporter \
  od
do
  SRC="$KIT/wrappers/$wrapper"
  DST="$BIN/$wrapper"

  [ -f "$SRC" ] || {
    echo "Wrapper ausente: $SRC" >&2
    exit 4
  }

  # Importante: evita escrever através de symlink npm.
  rm -f "$DST"
  install -m 755 "$SRC" "$DST"
done

ok "wrappers"


log "Skills compartilhadas"

mkdir -p "$HOME/.codex-shared/skills"

rsync -a \
  "$KIT/skills/" \
  "$HOME/.codex-shared/skills/"

ok "Skills"


log "UI/UX Pro Max runtime"

UIPRO="$HOME/.local/bin/uipro"

if [ ! -x "$UIPRO" ]; then
  UIPRO="$(command -v uipro 2>/dev/null || true)"
fi

if [ -z "$UIPRO" ] || [ ! -x "$UIPRO" ]; then
  echo "UI/UX Pro Max CLI não encontrado." >&2
  exit 2
fi

TMP_UIUX="$(mktemp -d)"

if ! (
  cd "$TMP_UIUX"
  "$UIPRO" init --ai codex --offline --force >/dev/null
); then
  rm -rf "$TMP_UIUX"
  echo "Falha gerando Skill UI/UX Pro Max." >&2
  exit 2
fi

GENERATED_UIUX="$TMP_UIUX/.agents/skills/ui-ux-pro-max"

if [ ! -d "$GENERATED_UIUX" ]; then
  rm -rf "$TMP_UIUX"
  echo "Skill UI/UX Pro Max não foi gerada no local esperado." >&2
  exit 2
fi

rm -rf "$HOME/.codex-shared/skills/ui-ux-pro-max"

cp -R \
  "$GENERATED_UIUX" \
  "$HOME/.codex-shared/skills/ui-ux-pro-max"

rm -rf "$TMP_UIUX"

ok "UI/UX Pro Max $UI_UX_PRO_MAX_VERSION"

log "mcporter global"

mkdir -p "$HOME/.mcporter"

install -m 644 \
  "$KIT/templates/mcporter/global.json" \
  "$HOME/.mcporter/mcporter.json"

ok "mcporter.json"


log "Diretórios runtime"

mkdir -p \
  "$HOME/.serena" \
  "$HOME/.semgrep"


log "VS Code"

if command -v code >/dev/null 2>&1; then
  if code --list-extensions 2>/dev/null |
       grep -qx 'openai.chatgpt'; then
    ok "extensão openai.chatgpt"
  else
    code --install-extension openai.chatgpt || \
      warn "não foi possível instalar openai.chatgpt"
  fi
else
  warn "VS Code não encontrado; instalação do editor fica para adapter de SO"
fi


log "Validação"

bash -n "$BIN/codex-code"
bash -n "$BIN/chrome-devtools"
bash -n "$BIN/mcporter"
bash -n "$BIN/od"

python3 -m json.tool \
  "$HOME/.mcporter/mcporter.json" \
  >/dev/null

"$NODE" --version
codex --version
rtk --version
openspec --version
codegraph --version
serena --version
mcporter --version
ctx7 --version
bd --version
repomix --version
semgrep --version
agent-browser --version
playwright-cli --version
chrome-devtools --version

od --help >/dev/null

echo
echo "================================================"
echo " bootstrap-machine concluído com sucesso"
echo "================================================"
