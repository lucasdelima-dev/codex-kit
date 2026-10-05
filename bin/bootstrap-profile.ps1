$ErrorActionPreference = "Stop"

$Script = Join-Path $PSScriptRoot "windows\bootstrap-profile.ps1"

if (-not (Test-Path $Script)) {
    throw "bootstrap-profile Windows ausente: $Script"
}

& $Script @args
exit $LASTEXITCODE
