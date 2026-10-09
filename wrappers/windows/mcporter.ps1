$ErrorActionPreference = "Stop"

$Node24 = Join-Path $HOME ".local\opt\node24"
$Root   = Join-Path $HOME ".local\share\mcporter"
$Node   = Join-Path $Node24 "node.exe"
$Cli    = Join-Path $Root "node_modules\mcporter\dist\cli.js"

if (-not (Test-Path $Node)) {
    throw "Node 24 não encontrado em $Node"
}

if (-not (Test-Path $Cli)) {
    throw "mcporter não encontrado em $Cli"
}

$env:Path = "$Node24;$Root\node_modules\.bin;$env:Path"

if ($env:CODEX_PROJECT_ROOT) {
    Set-Location $env:CODEX_PROJECT_ROOT
}

& $Node $Cli @args
exit $LASTEXITCODE
