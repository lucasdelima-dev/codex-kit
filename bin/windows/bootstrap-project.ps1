param(
    [Parameter(Position = 0)]
    [string]$Path = ".",

    [switch]$Beads,
    [switch]$OpenSpec,
    [switch]$Standard,
    [switch]$DbHub
)

$ErrorActionPreference = "Stop"

$Kit = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
. (Join-Path $Kit "platform\windows\common.ps1")

if ($Standard) {
    $Beads = $true
    $OpenSpec = $true
}

$Resolved = (Resolve-Path $Path).Path

$GitRootRaw = & git -C $Resolved rev-parse --show-toplevel 2>$null

if ($LASTEXITCODE -ne 0 -or -not $GitRootRaw) {
    throw "O caminho informado não pertence a um repositório Git: $Resolved"
}

$Root = (Resolve-Path $GitRootRaw.Trim()).Path

Write-Host ""
Write-Host "Projeto: $Root"


Write-Step "Isolamento Git"

$ExcludeRaw = & git -C $Root rev-parse --git-path info/exclude

if ($LASTEXITCODE -ne 0 -or -not $ExcludeRaw) {
    throw "Não foi possível localizar .git/info/exclude"
}

$ExcludePath = $ExcludeRaw.Trim()

if (-not [IO.Path]::IsPathRooted($ExcludePath)) {
    $ExcludePath = Join-Path $Root $ExcludePath
}

$ExcludeDir = Split-Path -Parent $ExcludePath
Ensure-Directory $ExcludeDir

if (-not (Test-Path $ExcludePath)) {
    New-Item -ItemType File -Path $ExcludePath | Out-Null
}

$Existing = @(
    Get-Content $ExcludePath -ErrorAction SilentlyContinue |
    ForEach-Object { $_.Trim() }
)

$TemplateExclude = Join-Path $Kit "templates\project\git-info-exclude.txt"

if (-not (Test-Path $TemplateExclude)) {
    throw "Template git-info-exclude ausente."
}

foreach ($Line in Get-Content $TemplateExclude) {
    $Pattern = $Line.Trim()

    if (-not $Pattern -or $Pattern.StartsWith("#")) {
        continue
    }

    if ($Existing -notcontains $Pattern) {
        Add-Content -Path $ExcludePath -Value $Pattern
        $Existing += $Pattern
    }
}

Write-Ok ".git/info/exclude"


Write-Step "Camada semântica"

Write-Ok "Serena será inicializado sob demanda"
Write-Ok "CodeGraph será inicializado sob demanda"


if ($Beads) {
    Write-Step "Beads"

    $BeadsDir = Join-Path $Root ".beads"

    if (Test-Path $BeadsDir) {
        Write-Ok "já inicializado"
    }
    else {
        $Bd = Join-Path $HOME ".local\bin\bd.exe"

        if (-not (Test-Path $Bd)) {
            throw "Beads CLI não encontrado: $Bd"
        }

        Push-Location $Root

        try {
            & $Bd init --stealth

            if ($LASTEXITCODE -ne 0) {
                throw "Falha inicializando Beads."
            }
        }
        finally {
            Pop-Location
        }

        Write-Ok "Beads inicializado"
    }
}


if ($OpenSpec) {
    Write-Step "OpenSpec"

    $OpenSpecDir = Join-Path $Root "openspec"

    if (Test-Path $OpenSpecDir) {
        Write-Ok "já inicializado"
    }
    else {
        $OpenSpecCmd = Join-Path $HOME ".local\npm\openspec.cmd"

        if (-not (Test-Path $OpenSpecCmd)) {
            throw "OpenSpec CLI não encontrado: $OpenSpecCmd"
        }

        Push-Location $Root

        try {
            & $OpenSpecCmd `
                init `
                --tools none `
                --no-animation

            if ($LASTEXITCODE -ne 0) {
                throw "Falha inicializando OpenSpec."
            }
        }
        finally {
            Pop-Location
        }

        Write-Ok "OpenSpec inicializado"
    }
}


if ($DbHub) {
    Write-Step "DBHub"

    $LocalRoot = Join-Path $Root ".codex-local"
    $LocalBin = Join-Path $LocalRoot "bin"
    $DbHubRoot = Join-Path $LocalRoot "dbhub"

    Ensure-Directory $LocalRoot
    Ensure-Directory $LocalBin
    Ensure-Directory $DbHubRoot

    $Config = Join-Path $DbHubRoot "dbhub.toml"
    $ConfigTemplate = Join-Path $Kit "templates\project\dbhub.toml"

    if (-not (Test-Path $Config)) {
        Copy-Item $ConfigTemplate $Config
        Write-Ok "dbhub.toml criado"
    }
    else {
        Write-Ok "dbhub.toml existente preservado"
    }

    $WrapperSource = Join-Path $Kit "templates\project\windows\dbhub.ps1"
    $WrapperPs = Join-Path $LocalBin "dbhub.ps1"
    $WrapperCmd = Join-Path $LocalBin "dbhub.cmd"

    if (-not (Test-Path $WrapperPs)) {
        Copy-Item $WrapperSource $WrapperPs
        Write-Ok "wrapper DBHub criado"
    }
    else {
        Write-Ok "wrapper DBHub existente preservado"
    }

    if (-not (Test-Path $WrapperCmd)) {
        $CmdText = @'
@echo off
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0dbhub.ps1" %*
'@

        Set-Content `
            -Path $WrapperCmd `
            -Value $CmdText `
            -Encoding ASCII

        Write-Ok "launcher DBHub criado"
    }
    else {
        Write-Ok "launcher DBHub existente preservado"
    }


    Write-Step "mcporter local"

    $ConfigDir = Join-Path $Root "config"
    $McporterFile = Join-Path $ConfigDir "mcporter.json"

    Ensure-Directory $ConfigDir

    if (Test-Path $McporterFile) {
        try {
            $Mcporter = Get-Content $McporterFile -Raw | ConvertFrom-Json
        }
        catch {
            throw "config/mcporter.json existente é inválido."
        }
    }
    else {
        $Mcporter = [PSCustomObject]@{
            '$schema' = 'https://raw.githubusercontent.com/openclaw/mcporter/main/mcporter.schema.json'
            imports = @()
            mcpServers = [PSCustomObject]@{}
        }
    }

    if (-not $Mcporter.PSObject.Properties["imports"]) {
        $Mcporter |
            Add-Member `
                -NotePropertyName imports `
                -NotePropertyValue @()
    }

    if (-not $Mcporter.PSObject.Properties["mcpServers"]) {
        $Mcporter |
            Add-Member `
                -NotePropertyName mcpServers `
                -NotePropertyValue ([PSCustomObject]@{})
    }

    $Servers = $Mcporter.mcpServers

    $DbHubNode = Join-Path $HOME ".local\opt\node24\node.exe"
    $DbHubCli = Join-Path $HOME ".local\npm\node_modules\@bytebase\dbhub\dist\index.js"

    $DbHubEntry = $Servers.PSObject.Properties["dbhub"]
    $LegacyManaged = $false

    if ($DbHubEntry) {
        $Existing = $DbHubEntry.Value

        $LegacyManaged = (
            $Existing.description -eq "DBHub local readonly deste projeto" -and
            (
                $Existing.command -eq '${CODEX_PROJECT_ROOT}\.codex-local\bin\dbhub.cmd' -or
                $Existing.command -eq "powershell.exe"
            )
        )
    }

    if (-not $DbHubEntry -or $LegacyManaged) {
        $DbHubDefinition = [PSCustomObject]@{
            description = "DBHub local readonly deste projeto"
            command = $DbHubNode
            args = @(
                $DbHubCli
                "--transport"
                "stdio"
                "--config"
                '${CODEX_PROJECT_ROOT}\.codex-local\dbhub\dbhub.toml'
            )
            cwd = '${CODEX_PROJECT_ROOT}'
        }

        if ($DbHubEntry) {
            $DbHubEntry.Value = $DbHubDefinition
        }
        else {
            $Servers |
                Add-Member `
                    -NotePropertyName dbhub `
                    -NotePropertyValue $DbHubDefinition
        }

        $Mcporter |
            ConvertTo-Json -Depth 20 |
            Set-Content `
                -Path $McporterFile `
                -Encoding UTF8

        Write-Ok "DBHub MCP configurado com Node nativo"
    }
    elseif ($DbHubEntry.Value.command -eq $DbHubNode) {
        Write-Ok "DBHub MCP nativo já configurado"
    }
    else {
        Write-Warning "DBHub personalizado preservado; confira a configuração manualmente."
    }

    if ([string]::IsNullOrWhiteSpace($env:DBHUB_DSN)) {
        Write-Warning "DBHUB_DSN não definido; DBHub ficará offline até a conexão ser configurada."
    }
}


Write-Step "Estado Git"

& git -C $Root status --short

Write-Host ""
Write-Host "========================================"
Write-Host " bootstrap-project Windows concluído"
Write-Host "========================================"
