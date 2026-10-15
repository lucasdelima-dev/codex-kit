#!/usr/bin/env python3
"""Smoke do runtime nativo e protocolo MCP do CodeGraph instalado."""

import json
import os
import queue
import re
import subprocess
import tempfile
import threading
import time
from pathlib import Path

KIT = Path(__file__).resolve().parent.parent
HOME = Path.home()

manifest = (KIT / "manifests/tools.env").read_text()

match = re.search(
    r'^CODEGRAPH_VERSION="([^"]+)"$',
    manifest,
    re.MULTILINE,
)

assert match, "Versão CodeGraph ausente do manifesto"
expected_version = match.group(1)

if os.name == "nt":
    node = HOME / ".local/opt/node24/node.exe"
    npm_root = HOME / ".local/npm"
else:
    node = HOME / ".local/opt/node24/bin/node"
    npm_root = HOME / ".local/lib"

cli = (
    npm_root
    / "node_modules/@lzehrung/codegraph/dist/bin/cli.js"
)

assert node.is_file(), f"Node ausente: {node}"
assert cli.is_file(), f"CLI ausente: {cli}"

print("=== CODEGRAPH INSTALADO ===", flush=True)


def run_cli(arguments, cwd, timeout=60):
    result = subprocess.run(
        [str(node), str(cli), *arguments],
        cwd=cwd,
        capture_output=True,
        text=True,
        encoding="utf-8",
        errors="replace",
        timeout=timeout,
    )

    if result.returncode != 0:
        raise RuntimeError(
            f"CodeGraph retornou {result.returncode}\n"
            f"{result.stdout[-1500:]}\n"
            f"{result.stderr[-1500:]}"
        )

    return result.stdout


with tempfile.TemporaryDirectory(
    prefix="codex-kit-codegraph-mcp-"
) as temporary:
    root = Path(temporary).resolve()
    fixture = root / "fixture"
    source = fixture / "src"
    source.mkdir(parents=True)

    (source / "math.ts").write_text(
        "export function somar(a: number, b: number): number {\n"
        "  return a + b;\n"
        "}\n",
        encoding="utf-8",
    )

    (source / "main.ts").write_text(
        'import { somar } from "./math";\n'
        "export const resultado = somar(2, 3);\n",
        encoding="utf-8",
    )

    version = run_cli(["--version"], fixture).strip()

    assert version == expected_version, (
        f"Versão instalada {version}; "
        f"esperada {expected_version}"
    )

    print(f"[OK] CodeGraph {version}", flush=True)

    print("\n=== RUNTIME NATIVO ===", flush=True)

    doctor = run_cli(["doctor"], fixture)

    assert re.search(
        r"Available:\s*yes\b", doctor
    ), "Runtime nativo indisponível"

    assert "codegraph-native" in doctor, (
        "Origem do módulo nativo não identificada"
    )

    print("[OK] Módulo nativo carregado", flush=True)

    print("\n=== INICIAR MCP STDIO ===", flush=True)

    stderr_file = root / "mcp-stderr.log"

    with stderr_file.open("wb") as stderr:
        process = subprocess.Popen(
            [
                str(node),
                str(cli),
                "mcp",
                "serve",
                "--root",
                str(fixture),
                "--stdio",
                "--no-warmup",
            ],
            cwd=fixture,
            stdin=subprocess.PIPE,
            stdout=subprocess.PIPE,
            stderr=stderr,
            text=True,
            encoding="utf-8",
            errors="replace",
            bufsize=1,
        )

        responses = queue.Queue()

        def read_messages():
            try:
                for line in process.stdout:
                    responses.put(line)
            finally:
                responses.put(None)

        reader = threading.Thread(
            target=read_messages,
            daemon=True,
        )
        reader.start()

        def send(message):
            process.stdin.write(
                json.dumps(message, separators=(",", ":"))
                + "\n"
            )
            process.stdin.flush()

        def receive(request_id, timeout_seconds):
            deadline = time.monotonic() + timeout_seconds

            while True:
                remaining = deadline - time.monotonic()

                if remaining <= 0:
                    raise TimeoutError(
                        f"MCP request {request_id} expirou"
                    )

                try:
                    line = responses.get(
                        timeout=min(remaining, 5)
                    )
                except queue.Empty:
                    if process.poll() is not None:
                        raise RuntimeError(
                            "Servidor MCP encerrou prematuramente"
                        )
                    continue

                if line is None:
                    raise RuntimeError(
                        "Servidor MCP fechou stdout"
                    )

                if not line.strip():
                    continue

                message = json.loads(line)

                if message.get("id") != request_id:
                    continue

                if "error" in message:
                    raise RuntimeError(
                        f"Erro MCP: {message['error']}"
                    )

                return message["result"]

        try:
            print("\n=== 1/3: INITIALIZE ===", flush=True)

            send({
                "jsonrpc": "2.0",
                "id": 1,
                "method": "initialize",
                "params": {
                    "protocolVersion": "2025-06-18",
                    "capabilities": {},
                    "clientInfo": {
                        "name": "codex-kit-smoke",
                        "version": "1.0.0",
                    },
                },
            })

            initialized = receive(1, 60)
            info = initialized.get("serverInfo", {})

            assert info.get("name") == "codegraph"
            assert info.get("version") == expected_version

            print("[OK] Handshake MCP aprovado", flush=True)

            send({
                "jsonrpc": "2.0",
                "method": "notifications/initialized",
            })

            print("\n=== 2/3: TOOLS/LIST ===", flush=True)

            send({
                "jsonrpc": "2.0",
                "id": 2,
                "method": "tools/list",
                "params": {},
            })

            listing = receive(2, 60)
            tools = listing.get("tools", [])

            names = {
                item.get("name")
                for item in tools
                if isinstance(item, dict)
            }

            assert {"orient", "search"} <= names

            print(
                f"[OK] {len(names)} ferramentas disponíveis",
                flush=True,
            )

            print("\n=== 3/3: TOOLS/CALL ===", flush=True)

            send({
                "jsonrpc": "2.0",
                "id": 3,
                "method": "tools/call",
                "params": {
                    "name": "search",
                    "arguments": {
                        "query": "somar",
                        "mode": "symbol",
                        "limit": 10,
                    },
                },
            })

            result = receive(3, 120)

            assert result.get("isError") is not True

            documents = []

            for item in result.get("content", []):
                if item.get("type") == "text":
                    documents.append(json.loads(item["text"]))

            semantic_match = False

            for document in documents:
                analysis = document.get("analysis", {})

                if analysis.get("backend") != "native":
                    continue

                for item in document.get("results", []):
                    filename = str(
                        item.get("file", "")
                    ).replace("\\", "/")

                    if (
                        item.get("label") == "somar"
                        and filename.endswith("src/math.ts")
                    ):
                        semantic_match = True

            assert semantic_match, (
                "Busca MCP não confirmou o símbolo nativo"
            )

            print("[OK] Símbolo somar localizado", flush=True)
            print("[OK] Backend semântico nativo confirmado")
            print("[OK] Handshake MCP completo aprovado")

        except BaseException:
            stderr.flush()
            print("\n=== LOG MCP ===", flush=True)
            print(
                stderr_file.read_text(
                    encoding="utf-8",
                    errors="replace",
                )[-2500:],
                flush=True,
            )
            raise

        finally:
            if process.stdin and not process.stdin.closed:
                process.stdin.close()

            try:
                process.wait(timeout=5)
            except subprocess.TimeoutExpired:
                process.terminate()

                try:
                    process.wait(timeout=5)
                except subprocess.TimeoutExpired:
                    process.kill()
                    process.wait(timeout=5)

            process.stdout.close()

            print("[OK] Servidor MCP encerrado", flush=True)

print("\n[OK] CodeGraph native MCP smoke aprovado")
