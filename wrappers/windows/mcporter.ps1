$ErrorActionPreference = "Stop"

$Node24 = Join-Path $HOME ".local\opt\node24"
$Root   = Join-Path $HOME ".local\share\mcporter"
$Cli    = Join-Path $Root "node_modules\.bin\mcporter.cmd"

if (-not (Test-Path $Cli)) {
    throw "mcporter não encontrado em $Cli"
}

$env:Path = "$Node24;$Root\node_modules\.bin;$env:Path"

if ($env:CODEX_PROJECT_ROOT) {
    Set-Location $env:CODEX_PROJECT_ROOT
}

& $Cli @args
exit $LASTEXITCODE
