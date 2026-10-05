$ErrorActionPreference = "Stop"

$Node      = Join-Path $HOME ".local\opt\node24\node.exe"
$NpmPrefix = Join-Path $HOME ".local\npm"
$Real      = Join-Path $NpmPrefix "node_modules\chrome-devtools-mcp\build\src\bin\chrome-devtools.js"

if (-not (Test-Path $Node)) {
    throw "Node 24 não encontrado em $Node"
}

if (-not (Test-Path $Real)) {
    throw "Chrome DevTools MCP não encontrado em $Real"
}

if ($args -contains "--version" -or $args -contains "-V") {
    & $Node $Real @args
    exit $LASTEXITCODE
}

if ($env:CODEX_PROJECT_ROOT) {
    $Root = (Resolve-Path $env:CODEX_PROJECT_ROOT).Path
}
else {
    $Root = (Get-Location).Path
}

$env:CHROME_DEVTOOLS_MCP_NO_USAGE_STATISTICS = "1"
$env:CHROME_DEVTOOLS_MCP_NO_UPDATE_CHECKS = "1"

$SecureArgs = @(
    "--headless"
    "--isolated"
    "--no-performance-crux"
    "--no-usage-statistics"
    "--redact-network-headers"
    "--no-category-extensions"
    "--no-category-experimental-third-party"
    "--no-category-experimental-webmcp"
    "--no-category-memory"
    "--filesystem-root=$Root"
)

& $Node $Real @SecureArgs @args
exit $LASTEXITCODE
