$ErrorActionPreference = "Stop"

$Profiles = @(
    "lean",
    "backend",
    "frontend",
    "research",
    "security",
    "full",
    "experimental",
    "intraer"
)

$Profile = "full"
$Target = (Get-Location).Path

if ($args.Count -ge 1) {
    if ($Profiles -contains $args[0]) {
        $Profile = $args[0]

        if ($args.Count -ge 2) {
            $Target = $args[1]
        }
    }
    else {
        $Target = $args[0]
    }
}

$Target = (Resolve-Path $Target).Path

$CodexHome = Join-Path $HOME ".codex-profiles\$Profile"
$VscodeData = Join-Path $HOME ".vscode-codex\$Profile"
$Extensions = Join-Path $HOME ".vscode\extensions"

if (-not (Test-Path $CodexHome)) {
    throw "Perfil Codex não encontrado: $CodexHome"
}

New-Item -ItemType Directory -Force -Path $VscodeData | Out-Null

$env:CODEX_HOME = $CodexHome
$env:CODEX_PROJECT_ROOT = $Target

Remove-Item Env:MCPORTER_CONFIG -ErrorAction SilentlyContinue

if ($Profile -eq "intraer") {
    $env:AGENT_BROWSER_NO_WEBMCP = "1"
    $env:NO_UPDATE_NOTIFIER = "1"
    $env:CHROME_DEVTOOLS_MCP_NO_USAGE_STATISTICS = "1"
    $env:CHROME_DEVTOOLS_MCP_NO_UPDATE_CHECKS = "1"
}

$Code = Get-Command code -ErrorAction SilentlyContinue

if (-not $Code) {
    throw "VS Code CLI 'code' não encontrado no PATH."
}

Write-Host "Perfil:     $Profile"
Write-Host "Projeto:    $Target"
Write-Host "CODEX_HOME: $CodexHome"

& $Code.Source `
    --new-window `
    --user-data-dir $VscodeData `
    --extensions-dir $Extensions `
    $Target

exit $LASTEXITCODE
