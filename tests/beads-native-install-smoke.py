#!/usr/bin/env python3
"""Teste isolado da migração Beads npm -> binário nativo em Unix."""

import hashlib
import os
import platform
import subprocess
import tarfile
import tempfile
from pathlib import Path


KIT = Path(__file__).resolve().parent.parent
SYSTEM = platform.system()
MACHINE = platform.machine()

if SYSTEM not in ("Linux", "Darwin"):
    raise SystemExit("Teste exclusivo para Linux/macOS")

ARCH = "x86_64" if MACHINE in ("x86_64", "amd64") else (
    "aarch64" if MACHINE in ("arm64", "aarch64") else None
)
assert ARCH, f"Arquitetura não suportada: {MACHINE}"

BEADS_ARCH = "amd64" if ARCH == "x86_64" else "arm64"
PLATFORM_DIR = "linux" if SYSTEM == "Linux" else "macos"
RELEASE_OS = "linux" if SYSTEM == "Linux" else "darwin"
HASH_KEY = (
    f"BEADS_SHA256_{'LINUX' if SYSTEM == 'Linux' else 'MACOS'}"
    f"_{'AMD64' if ARCH == 'x86_64' else 'ARM64'}"
)

manifest = (KIT / "manifests/tools.env").read_text()
assert f'{HASH_KEY}="' in manifest

script = (KIT / f"platform/{PLATFORM_DIR}/machine.sh").read_text()

start = 'log "Beads $BEADS_VERSION"\n'
end = 'log "pnpm para OpenDesign"\n'

assert script.count(start) == 1
assert script.count(end) == 1

block = script.split(start, 1)[1].split(end, 1)[0]

shell = (
    "#!/usr/bin/env bash\n"
    "set -euo pipefail\n"
    "log() { :; }\n"
    "ok() { :; }\n"
    + start + block
)

with tempfile.TemporaryDirectory(prefix="codex-beads-native-") as directory:
    root = Path(directory)

    source = root / "fixture.c"
    binary = root / "bd"

    source.write_text(
        '#include <stdio.h>\n'
        'int main(void) {\n'
        '  puts("bd version 1.3.1 (fixture nativa)");\n'
        '  return 0;\n'
        '}\n'
    )

    subprocess.run(
        ["cc", str(source), "-o", str(binary)],
        check=True,
        capture_output=True,
        text=True,
    )

    asset = f"beads_1.3.1_{RELEASE_OS}_{BEADS_ARCH}.tar.gz"
    archive = root / asset

    with tarfile.open(archive, "w:gz") as tar:
        tar.add(binary, arcname="bd")

    digest = hashlib.sha256(archive.read_bytes()).hexdigest()

    checksum = root / "checksums.txt"
    checksum.write_text(f"{digest}  {asset}\n")

    fake_bin = root / "fake-bin"
    fake_bin.mkdir()

    curl = fake_bin / "curl"
    curl.write_text(
        "#!/bin/sh\n"
        "set -eu\n"
        'test "$1" = "-fsSL"\n'
        'test "$3" = "-o"\n'
        'printf "%s\\n" "$2" >> "$MOCK_CURL_LOG"\n'
        'case "$2" in\n'
        '  */checksums.txt) cp "$MOCK_CHECKSUM" "$4" ;;\n'
        '  */beads_*.tar.gz) cp "$MOCK_ARCHIVE" "$4" ;;\n'
        '  *) exit 9 ;;\n'
        'esac\n'
    )
    curl.chmod(0o755)

    snippet = root / "install-beads.sh"
    snippet.write_text(shell)
    snippet.chmod(0o755)

    scratch = root / "scratch"
    scratch.mkdir()

    def prepare(label, unknown=False):
        prefix = root / label
        bin_dir = prefix / "bin"
        bin_dir.mkdir(parents=True)

        npm_wrapper = (
            prefix / "lib/node_modules/@beads/bd/bin/bd.js"
        )
        npm_wrapper.parent.mkdir(parents=True)
        npm_wrapper.write_text(
            "#!/bin/sh\n"
            "echo 'bd version 1.3.1 (wrapper npm)'\n"
        )
        npm_wrapper.chmod(0o755)

        target = bin_dir / "bd"

        if unknown:
            other = prefix / "outro-bd.js"
            other.write_text(npm_wrapper.read_text())
            other.chmod(0o755)
            target.symlink_to(other)
        else:
            target.symlink_to(npm_wrapper)

        return prefix, npm_wrapper, target

    def execute(prefix, pinned_hash, label):
        curl_log = root / f"{label}.curl.log"

        env = os.environ.copy()
        env.update({
            "PATH": f"{fake_bin}:{env.get('PATH', '')}",
            "TMPDIR": str(scratch),
            "OS": SYSTEM,
            "ARCH": ARCH,
            "PREFIX": str(prefix),
            "BIN": str(prefix / "bin"),
            "BEADS_VERSION": "1.3.1",
            HASH_KEY: pinned_hash,
            "MOCK_ARCHIVE": str(archive),
            "MOCK_CHECKSUM": str(checksum),
            "MOCK_CURL_LOG": str(curl_log),
        })

        result = subprocess.run(
            ["bash", str(snippet)],
            env=env,
            capture_output=True,
            text=True,
            timeout=30,
        )

        return result, curl_log

    print("=== 1. Migração de symlink npm ===")

    prefix, wrapper, target = prepare("migracao")
    original_wrapper = wrapper.read_bytes()

    result, curl_log = execute(prefix, digest, "migracao")

    assert result.returncode == 0, (
        result.stdout + "\n" + result.stderr
    )
    assert target.is_file() and not target.is_symlink()
    assert wrapper.read_bytes() == original_wrapper
    assert subprocess.check_output(
        [str(target)], text=True
    ).strip() == "bd version 1.3.1 (fixture nativa)"
    assert curl_log.exists()

    print("✅ Wrapper npm substituído pelo executável nativo")
    print("✅ Arquivos do pacote npm preservados")

    print("\n=== 2. Rejeição de checksum inválido ===")

    prefix, wrapper, target = prepare("hash-invalido")

    result, _ = execute(prefix, "0" * 64, "hash-invalido")

    assert result.returncode != 0
    assert "Checksum do Beads inválido" in result.stderr
    assert target.is_symlink()
    assert target.resolve() == wrapper.resolve()

    print("✅ Hash divergente rejeitado")
    print("✅ Symlink anterior preservado")

    print("\n=== 3. Rejeição de symlink desconhecido ===")

    prefix, wrapper, target = prepare(
        "symlink-desconhecido", unknown=True
    )

    original_destination = target.resolve()
    result, curl_log = execute(
        prefix, digest, "symlink-desconhecido"
    )

    assert result.returncode != 0
    assert "symlink bd desconhecido" in result.stderr
    assert target.is_symlink()
    assert target.resolve() == original_destination
    assert not curl_log.exists()

    print("✅ Symlink desconhecido preservado")
    print("✅ Nenhum download realizado")

print("\n✅ Beads native install smoke passou")
