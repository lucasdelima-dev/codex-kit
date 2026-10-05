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
