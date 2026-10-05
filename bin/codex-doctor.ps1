$ErrorActionPreference = "Stop"

$Script = Join-Path $PSScriptRoot "windows\codex-doctor.ps1"

if (-not (Test-Path $Script)) {
    throw "codex-doctor Windows ausente: $Script"
}

& $Script @args
exit $LASTEXITCODE
