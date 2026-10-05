param(
    [string]$Profile = "all"
)

$ErrorActionPreference = "Stop"

$Kit = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
. (Join-Path $Kit "platform\windows\common.ps1")

$Manifest = Join-Path $Kit "manifests\profiles.tsv"
$ToolsManifest = Join-Path $Kit "manifests\tools.env"

if (-not (Test-Path $Manifest)) {
    throw "Manifesto de perfis ausente: $Manifest"
}

$Versions = Read-EnvManifest $ToolsManifest
$SuperpowersVersion = $Versions["SUPERPOWERS_EXPECTED_VERSION"]

if (-not $SuperpowersVersion) {
    throw "SUPERPOWERS_EXPECTED_VERSION ausente em tools.env"
}

$Definitions = @{}

Get-Content $Manifest | ForEach-Object {
    $Line = $_.Trim()

    if (-not $Line -or $Line.StartsWith("#")) {
        return
    }

    $Parts = $Line -split '\|', 2

    if ($Parts.Count -ne 2) {
        throw "Linha inválida em profiles.tsv: $Line"
    }

    $Definitions[$Parts[0]] = @(
        $Parts[1] -split ',' |
        ForEach-Object { $_.Trim() } |
        Where-Object { $_ }
    )
}

if ($Profile -eq "all") {
    $Targets = @(
        "lean",
        "backend",
        "frontend",
        "research",
        "security",
        "full",
        "experimental",
        "intraer"
    )
}
elseif ($Definitions.ContainsKey($Profile)) {
    $Targets = @($Profile)
}
else {
    throw "Perfil inválido: $Profile"
}

$AuthSource = Join-Path $HOME ".codex\auth.json"
$CodexCmd = Join-Path $HOME ".local\npm\codex.cmd"

if (-not (Test-Path $AuthSource)) {
    throw @"
Autenticação Codex ausente:

    $AuthSource

Faça login no Codex antes de executar bootstrap-profile.
"@
}

if (-not (Test-Path $CodexCmd)) {
    throw "Codex CLI não encontrado: $CodexCmd"
}

foreach ($Name in $Targets) {
    Write-Step "Perfil: $Name"

    $Template = Join-Path $Kit "templates\profiles\$Name"
    $Root = Join-Path $ProfilesRoot $Name
    $Rules = Join-Path $Root "rules"
    $SkillsRoot = Join-Path $Root "skills"

    foreach ($Required in @(
        "config.toml",
        "AGENTS.md",
        "rules\default.rules"
    )) {
        if (-not (Test-Path (Join-Path $Template $Required))) {
            throw "${Name}: template ausente: $Required"
        }
    }

    Ensure-Directory $Root
    Ensure-Directory $Rules

    Copy-Item `
        (Join-Path $Template "config.toml") `
        (Join-Path $Root "config.toml") `
        -Force

    Copy-Item `
        (Join-Path $Template "AGENTS.md") `
        (Join-Path $Root "AGENTS.md") `
        -Force

    Copy-Item `
        (Join-Path $Template "rules\default.rules") `
        (Join-Path $Rules "default.rules") `
        -Force

    Write-Ok "config/AGENTS/rules"

    $AuthLink = Join-Path $Root "auth.json"

    if (Test-Path $AuthLink) {
        $Existing = Get-Item $AuthLink -Force

        if ($Existing.Attributes -band [IO.FileAttributes]::ReparsePoint) {
            Remove-Item $AuthLink -Force
        }
        else {
            throw @"
$AuthLink existe como arquivo normal.

Por segurança o bootstrap não sobrescreve nem duplica auth.json.
Remova-o manualmente depois de confirmar o conteúdo.
"@
        }
    }

    try {
        New-Item `
            -ItemType SymbolicLink `
            -Path $AuthLink `
            -Target $AuthSource `
            -Force |
            Out-Null
    }
    catch {
        throw @"
Não foi possível criar o symlink de auth.json.

No Windows, habilite Developer Mode:
Settings > System > Advanced > For developers > Developer Mode

O bootstrap deliberadamente não copia credenciais entre perfis.
"@
    }

    Write-Ok "auth symlink"

    if (Test-Path $SkillsRoot) {
        Remove-Item $SkillsRoot -Recurse -Force
    }

    Ensure-Directory $SkillsRoot

    foreach ($Skill in $Definitions[$Name]) {
        $Source = Join-Path $SharedSkills $Skill
        $Destination = Join-Path $SkillsRoot $Skill

        if (-not (Test-Path $Source)) {
            throw "${Name}: Skill compartilhada ausente: $Skill"
        }

        New-Item `
            -ItemType Junction `
            -Path $Destination `
            -Target $Source |
            Out-Null
    }

    $Count = @(
        Get-ChildItem $SkillsRoot -Force |
        Where-Object {
            $_.Attributes -band [IO.FileAttributes]::ReparsePoint
        }
    ).Count

    $Expected = $Definitions[$Name].Count

    if ($Count -ne $Expected) {
        throw "${Name}: skills $Count/$Expected"
    }

    Write-Ok "skills: $Count"

    $Plugins = Join-Path $Root "plugins"
    $SuperpowersPresent = $false

    if (Test-Path $Plugins) {
        $SuperpowersPresent = @(
            Get-ChildItem $Plugins -Recurse -Force -ErrorAction SilentlyContinue |
            Where-Object {
                $_.FullName -like "*superpowers*$SuperpowersVersion*"
            }
        ).Count -gt 0
    }

    if (-not $SuperpowersPresent) {
        $OldCodexHome = $env:CODEX_HOME
        $env:CODEX_HOME = $Root

        try {
            & $CodexCmd `
                plugin add `
                superpowers@openai-curated-remote `
                --json

            if ($LASTEXITCODE -ne 0) {
                throw "${Name}: instalação do Superpowers falhou."
            }
        }
        finally {
            if ($null -eq $OldCodexHome) {
                Remove-Item Env:CODEX_HOME -ErrorAction SilentlyContinue
            }
            else {
                $env:CODEX_HOME = $OldCodexHome
            }
        }

        $SuperpowersPresent = @(
            Get-ChildItem $Plugins -Recurse -Force -ErrorAction SilentlyContinue |
            Where-Object {
                $_.FullName -like "*superpowers*$SuperpowersVersion*"
            }
        ).Count -gt 0
    }

    if (-not $SuperpowersPresent) {
        throw "${Name}: Superpowers $SuperpowersVersion não encontrado."
    }

    Write-Ok "superpowers $SuperpowersVersion"
}

Write-Host ""
Write-Host "========================================"
Write-Host " bootstrap-profile Windows concluído"
Write-Host "========================================"
