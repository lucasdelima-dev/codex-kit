$ErrorActionPreference = "Stop"

$Version = "0.24.1"
$Node    = Join-Path $HOME ".local\opt\node24\node.exe"
$Root    = Join-Path $HOME ".local\share\open-design-$Version"
$Cli     = Join-Path $Root "apps\daemon\dist\cli.js"

if (-not (Test-Path $Node)) {
    throw "Node 24 não encontrado em $Node"
}

if (-not (Test-Path $Cli)) {
    throw "OpenDesign CLI não encontrada em $Cli"
}

Remove-Item Env:POSTHOG_KEY -ErrorAction SilentlyContinue
Remove-Item Env:POSTHOG_HOST -ErrorAction SilentlyContinue
Remove-Item Env:OPEN_DESIGN_TELEMETRY_RELAY_URL -ErrorAction SilentlyContinue
Remove-Item Env:LANGFUSE_BASE_URL -ErrorAction SilentlyContinue

$env:NEXT_TELEMETRY_DISABLED = "1"
$env:Path = "$(Split-Path $Node -Parent);$env:Path"

& $Node $Cli @args
exit $LASTEXITCODE
