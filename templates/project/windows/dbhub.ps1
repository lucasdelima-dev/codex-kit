$ErrorActionPreference = "Stop"

$Real = Join-Path $HOME ".local\npm\dbhub.cmd"

if (-not (Test-Path $Real)) {
    throw "DBHub não encontrado em $Real"
}

if ($args -contains "--version" -or $args -contains "-V") {
    & $Real @args
    exit $LASTEXITCODE
}

if ($env:CODEX_PROJECT_ROOT) {
    $Root = (Resolve-Path $env:CODEX_PROJECT_ROOT).Path
}
else {
    $Detected = (& git rev-parse --show-toplevel 2>$null)

    if ($LASTEXITCODE -ne 0 -or -not $Detected) {
        throw "Não foi possível determinar o projeto atual."
    }

    $Root = (Resolve-Path $Detected.Trim()).Path
}

$Config = Join-Path $Root ".codex-local\dbhub\dbhub.toml"

if (-not (Test-Path $Config)) {
    throw "Config DBHub local ausente: $Config"
}

$Raw = Get-Content $Config -Raw

if (
    $Raw -match '\$\{DBHUB_DSN\}' -and
    [string]::IsNullOrWhiteSpace($env:DBHUB_DSN)
) {
    throw @"
DBHUB_DSN não definido.

Defina a conexão autorizada para este projeto antes de iniciar o DBHub.
"@
}

& $Real `
    --transport stdio `
    --config $Config `
    @args

exit $LASTEXITCODE
