#!/usr/bin/env bash

log() {
  printf '\n==> %s\n' "$*"
}

ok() {
  printf '    OK: %s\n' "$*"
}

warn() {
  printf '    AVISO: %s\n' "$*" >&2
}

pkg_version() {
  local file="$1"

  [ -f "$file" ] || return 1

  "$NODE" -e '
    const fs = require("fs");
    const p = JSON.parse(fs.readFileSync(process.argv[1], "utf8"));
    process.stdout.write(String(p.version || ""));
  ' "$file"
}

ensure_npm() {
  local pkg="$1"
  local wanted="$2"
  local json="$PREFIX/lib/node_modules/$pkg/package.json"
  local current=""

  current="$(pkg_version "$json" 2>/dev/null || true)"

  if [ "$current" = "$wanted" ]; then
    ok "$pkg@$wanted"
    return
  fi

  log "Instalando $pkg@$wanted"
  "$NPM" install -g --prefix "$PREFIX" "$pkg@$wanted"
}

ensure_uv_tool() {
  local pkg="$1"
  local wanted="$2"
  local current=""

  current="$("$UV" tool list 2>/dev/null |
    awk -v name="$pkg" '$1 == name {gsub(/^v/, "", $2); print $2; exit}')"

  if [ "$current" = "$wanted" ]; then
    ok "$pkg@$wanted"
    return
  fi

  log "Instalando $pkg==$wanted"
  "$UV" tool install --force "$pkg==$wanted"
}


# Instalação controlada do agent-browser: nunca executar seu postinstall.
agent_browser_sha256() {
  case "$(uname -s)" in
    Linux)
      sha256sum "$1" | awk '{print $1}'
      ;;
    Darwin)
      shasum -a 256 "$1" | awk '{print $1}'
      ;;
    *)
      return 2
      ;;
  esac
}

ensure_agent_browser() {
  local platform_key="$1"
  local arch_key="$2"
  local expected="$3"

  local root="$PREFIX/lib/node_modules/agent-browser"
  local asset="agent-browser-$platform_key-$arch_key"
  local target="$root/bin/$asset"
  local current=""

  current="$(pkg_version "$root/package.json" 2>/dev/null || true)"

  if [ "$current" != "$AGENT_BROWSER_VERSION" ]; then
    log "Instalando agent-browser@$AGENT_BROWSER_VERSION sem postinstall"

    "$NPM" install \
      -g \
      --prefix "$PREFIX" \
      --ignore-scripts \
      "agent-browser@$AGENT_BROWSER_VERSION"
  fi

  [ -f "$root/bin/agent-browser.js" ] || {
    echo "ERRO: wrapper do agent-browser ausente." >&2
    return 3
  }

  local actual=""
  if [ -f "$target" ]; then
    actual="$(agent_browser_sha256 "$target")"
  fi

  if [ "$actual" != "$expected" ]; then
    (
      set -e

      local tmp
      tmp="$(mktemp -d)"
      trap 'rm -rf "$tmp"' EXIT

      local url="https://github.com/vercel-labs/agent-browser/releases/download/v$AGENT_BROWSER_VERSION/$asset"

      curl -fsSL "$url" -o "$tmp/$asset"

      local downloaded
      downloaded="$(agent_browser_sha256 "$tmp/$asset")"

      if [ "$downloaded" != "$expected" ]; then
        echo "ERRO: SHA-256 inválido do agent-browser: $asset" >&2
        exit 3
      fi

      install -m 755 "$tmp/$asset" "$target"
    ) || return 3
  fi

  if [ "$(agent_browser_sha256 "$target")" != "$expected" ]; then
    echo "ERRO: verificação final do agent-browser falhou." >&2
    return 3
  fi

  chmod 755 "$target"
  ok "agent-browser@$AGENT_BROWSER_VERSION SHA-256 validado"
}
