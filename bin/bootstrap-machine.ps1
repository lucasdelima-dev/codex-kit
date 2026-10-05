$ErrorActionPreference = "Stop"

$Kit = Split-Path -Parent $PSScriptRoot
$Machine = Join-Path $Kit "platform\windows\machine.ps1"

if (-not (Test-Path $Machine)) {
    throw "Adapter Windows ausente: $Machine"
}

& $Machine @args
exit $LASTEXITCODE
