#!/usr/bin/env python3
"""Regressão isolada da resolução CODEX_PROJECT_ROOT no mcporter Unix."""

import os
import platform
import subprocess
import tempfile
from pathlib import Path


assert platform.system() in ("Linux", "Darwin")

KIT = Path(__file__).resolve().parent.parent
WRAPPER = KIT / "wrappers/mcporter"

assert WRAPPER.is_file()


def check(condition, message):
    if not condition:
        raise AssertionError(message)
    print(f"✅ {message}")


with tempfile.TemporaryDirectory(
    prefix="codex-kit-mcporter-"
) as temporary:
    base = Path(temporary)
    home = base / "home"
    project = base / "projeto com espacos"
    nested = project / "src" / "modulo"
    outside = base / "fora do git"

    nested.mkdir(parents=True)
    outside.mkdir()

    subprocess.run(
        ["git", "init", "-q", str(project)],
        check=True,
        capture_output=True,
        text=True,
    )

    fake = (
        home / ".local/share/mcporter"
        / "node_modules/.bin/mcporter"
    )

    fake.parent.mkdir(parents=True)

    fake.write_text(
        "#!/usr/bin/env bash\n"
        'printf "root=%s\\n" "${CODEX_PROJECT_ROOT-<unset>}"\n'
        'printf "cwd=%s\\n" "$(pwd -P)"\n'
        'printf "argc=%s\\n" "$#"\n'
        'for arg in "$@"; do\n'
        '  printf "arg=%s\\n" "$arg"\n'
        'done\n',
        encoding="utf-8",
    )

    fake.chmod(0o700)

    environment = os.environ.copy()
    environment["HOME"] = str(home)
    environment.pop("CODEX_PROJECT_ROOT", None)

    args = [
        "call",
        "serena.find_symbol",
        "--args",
        '{"name_path_pattern":"Classe Exemplo"}',
        "--output",
        "text",
    ]

    def execute(cwd, env):
        return subprocess.run(
            [str(WRAPPER), *args],
            cwd=cwd,
            env=env,
            capture_output=True,
            text=True,
            timeout=15,
        )

    def expected_output(root_value, cwd_value):
        return [
            f"root={root_value}",
            f"cwd={cwd_value}",
            f"argc={len(args)}",
            *(f"arg={argument}" for argument in args),
        ]

    print("\n=== TESTE 1: RAIZ GIT AUTOMÁTICA ===")

    result = execute(nested, environment)

    check(
        result.returncode == 0
        and result.stdout.splitlines()
        == expected_output(str(project), str(project)),
        "Raiz Git descoberta a partir de subdiretório",
    )

    print("\n=== TESTE 2: VARIÁVEL EXPLÍCITA ===")

    explicit = environment.copy()
    explicit["CODEX_PROJECT_ROOT"] = str(outside)

    result = execute(nested, explicit)

    check(
        result.returncode == 0
        and result.stdout.splitlines()
        == expected_output(str(outside), str(outside)),
        "Variável explícita tem prioridade",
    )

    print("\n=== TESTE 3: FORA DE REPOSITÓRIO ===")

    result = execute(outside, environment)

    check(
        result.returncode == 0
        and result.stdout.splitlines()
        == expected_output("<unset>", str(outside)),
        "Comportamento fora do Git preservado",
    )

    print("\n=== TESTE 4: RAIZ INVÁLIDA ===")

    invalid = environment.copy()
    invalid["CODEX_PROJECT_ROOT"] = str(
        base / "diretorio inexistente"
    )

    result = execute(nested, invalid)

    check(
        result.returncode == 2
        and "ERRO: CODEX_PROJECT_ROOT inacessível"
        in result.stderr
        and not result.stdout,
        "Diretório inválido interrompe antes do mcporter",
    )

    print("\n=== TESTE 5: INTEGRIDADE DOS ARGUMENTOS ===")

    result = execute(nested, environment)

    check(
        result.returncode == 0
        and result.stdout.splitlines()[3:]
        == [f"arg={argument}" for argument in args],
        "Argumentos JSON e espaços preservados integralmente",
    )

print("\n✅ Cinco regressões do mcporter aprovadas")
