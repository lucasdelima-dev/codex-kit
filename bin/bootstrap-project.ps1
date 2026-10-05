$ErrorActionPreference = "Stop"

$Script = Join-Path $PSScriptRoot "windows\bootstrap-project.ps1"

if (-not (Test-Path $Script)) {
    throw "bootstrap-project Windows ausente: $Script"
}

& $Script @args
exit $LASTEXITCODE
