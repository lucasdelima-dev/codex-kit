$ErrorActionPreference = "Stop"

$Kit = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
. (Join-Path $Kit "platform\windows\common.ps1")

$ToolsManifest = Join-Path $Kit "manifests\tools.env"
$ProfilesManifest = Join-Path $Kit "manifests\profiles.tsv"

$Versions = Read-EnvManifest $ToolsManifest

$Pass = 0
$Warn = 0
$Fail = 0

function Ok {
    param([string]$Message)
    Write-Host "  ✅ $Message"
    $script:Pass++
}

function Warn {
    param([string]$Message)
    Write-Host "  ⚠️  $Message"
    $script:Warn++
}

function Fail {
    param([string]$Message)
    Write-Host "  ❌ $Message"
    $script:Fail++
}

function Section {
    param([string]$Message)

    Write-Host ""
    Write-Host "=== $Message ==="
}


Section "Sistema"

Write-Host "  SO:   Windows"

$Arch = [System.Runtime.InteropServices.RuntimeInformation]::OSArchitecture.ToString()

Write-Host "  ARCH: $Arch"

if ($IsWindows -or $env:OS -eq "Windows_NT") {
    Ok "Windows detectado"
}
else {
    Fail "doctor Windows executado fora do Windows"
}

if ($Arch -eq "X64") {
    Ok "arquitetura x64"
}
else {
    Warn "Windows nativo v1 foi implementado para x64"
}


Section "Node 24"

$ExpectedNode = "v$($Versions['NODE24_VERSION'])"
$Node24 = Join-Path $HOME ".local\opt\node24"
$NodeExe = Join-Path $Node24 "node.exe"

if (Test-Path $NodeExe) {
    $Current = & $NodeExe --version

    if ($Current -eq $ExpectedNode) {
        Ok "Node $Current"
    }
    else {
        Fail "Node esperado $ExpectedNode; encontrado $Current"
    }
}
else {
    Fail "Node24 ausente"
}

if (Test-Path $Node24) {
    $NodeItem = Get-Item $Node24 -Force

    if ($NodeItem.Attributes -band [IO.FileAttributes]::ReparsePoint) {
        Ok "alias node24 é Junction/Symlink"
    }
    else {
        Fail "node24 não é Junction/Symlink"
    }
}
else {
    Fail "alias node24 ausente"
}


Section "Ferramentas"

$Commands = @(
    "codex",
    "rtk",
    "openspec",
    "codegraph",
    "serena",
    "mcporter",
    "ctx7",
    "bd",
    "repomix",
    "semgrep",
    "agent-browser",
    "playwright-cli",
    "chrome-devtools",
    "od"
)

foreach ($Command in $Commands) {
    if (Get-Command $Command -ErrorAction SilentlyContinue) {
        Ok $Command
    }
    else {
        Fail "$Command ausente do PATH"
    }
}


Section "Wrappers"

foreach ($Name in @(
    "codex-code",
    "chrome-devtools",
    "mcporter",
    "od"
)) {
    $Template = Join-Path $Kit "wrappers\windows\$Name.ps1"
    $Active = Join-Path $HOME ".local\bin\$Name.ps1"

    if (-not (Test-Path $Template)) {
        Fail "$Name template ausente"
        continue
    }

    if (-not (Test-Path $Active)) {
        Fail "$Name ativo ausente"
        continue
    }

    $TemplateHash = (Get-FileHash $Template -Algorithm SHA256).Hash
    $ActiveHash = (Get-FileHash $Active -Algorithm SHA256).Hash

    if ($TemplateHash -eq $ActiveHash) {
        Ok "$Name ativo = template"
    }
    else {
        Warn "$Name ativo diverge do template"
    }

    $Launcher = Join-Path $HOME ".local\bin\$Name.cmd"

    if (Test-Path $Launcher) {
        Ok "$Name.cmd"
    }
    else {
        Fail "$Name.cmd ausente"
    }
}


Section "Configuração global"

$GlobalMcporter = Join-Path $HOME ".mcporter\mcporter.json"

if (Test-Path $GlobalMcporter) {
    try {
        Get-Content $GlobalMcporter -Raw |
            ConvertFrom-Json |
            Out-Null

        Ok "mcporter.json válido"
    }
    catch {
        Fail "mcporter.json inválido"
    }
}
else {
    Fail "mcporter.json global ausente"
}

$GlobalFiles = @(
    $GlobalMcporter
)

$GlobalFiles += Get-ChildItem `
    (Join-Path $Kit "templates\profiles") `
    -Recurse `
    -File `
    -ErrorAction SilentlyContinue |
    Select-Object -ExpandProperty FullName

$GlobalFiles += Get-ChildItem `
    (Join-Path $Kit "wrappers") `
    -Recurse `
    -File `
    -ErrorAction SilentlyContinue |
    Select-Object -ExpandProperty FullName

$Forbidden = @(
    '/home/[^/]+/',
    '/Users/[^/]+/',
    '[A-Za-z]:\\Users\\[^\\]+\\'
)

$Coupling = $false

foreach ($Pattern in $Forbidden) {
    $Hits = Select-String `
        -Path $GlobalFiles `
        -Pattern $Pattern `
        -ErrorAction SilentlyContinue

    if ($Hits) {
        $Coupling = $true
        break
    }
}

if ($Coupling) {
    Fail "caminho pessoal hardcoded encontrado"
}
else {
    Ok "camada global sem caminho pessoal hardcoded"
}


Section "Perfis"

$Definitions = @{}

Get-Content $ProfilesManifest | ForEach-Object {
    $Line = $_.Trim()

    if (-not $Line -or $Line.StartsWith("#")) {
        return
    }

    $Parts = $Line -split '\|', 2

    if ($Parts.Count -eq 2) {
        $Definitions[$Parts[0]] = @(
            $Parts[1] -split ',' |
            ForEach-Object { $_.Trim() } |
            Where-Object { $_ }
        )
    }
}

$Order = @(
    "lean",
    "backend",
    "frontend",
    "research",
    "security",
    "full",
    "experimental",
    "intraer"
)

$AuthSource = Join-Path $HOME ".codex\auth.json"
$SuperpowersVersion = $Versions["SUPERPOWERS_EXPECTED_VERSION"]

foreach ($Name in $Order) {
    $Root = Join-Path $ProfilesRoot $Name
    $ProfileOk = $true

    if (-not (Test-Path $Root)) {
        Fail "$Name ausente"
        continue
    }

    foreach ($Required in @(
        "config.toml",
        "AGENTS.md",
        "rules\default.rules"
    )) {
        if (-not (Test-Path (Join-Path $Root $Required))) {
            Fail "$Name`: $Required ausente"
            $ProfileOk = $false
        }
    }

    $AuthLink = Join-Path $Root "auth.json"

    if (-not (Test-Path $AuthLink)) {
        Fail "$Name`: auth.json ausente"
        $ProfileOk = $false
    }
    else {
        $AuthItem = Get-Item $AuthLink -Force

        if (-not (
            $AuthItem.Attributes -band
            [IO.FileAttributes]::ReparsePoint
        )) {
            Fail "$Name`: auth.json não é symlink"
            $ProfileOk = $false
        }
    }

    $SkillsRoot = Join-Path $Root "skills"

    $ExpectedSkills = $Definitions[$Name]
    $ExpectedCount = $ExpectedSkills.Count

    $ActualCount = 0

    if (Test-Path $SkillsRoot) {
        $ActualCount = @(
            Get-ChildItem $SkillsRoot -Force |
            Where-Object {
                $_.Attributes -band
                [IO.FileAttributes]::ReparsePoint
            }
        ).Count
    }

    if ($ActualCount -ne $ExpectedCount) {
        Fail "$Name`: skills $ActualCount/$ExpectedCount"
        $ProfileOk = $false
    }

    foreach ($Skill in $ExpectedSkills) {
        $Link = Join-Path $SkillsRoot $Skill
        $Source = Join-Path $SharedSkills $Skill

        if (-not (Test-Path $Link)) {
            Fail "$Name`: skill ausente: $Skill"
            $ProfileOk = $false
            continue
        }

        $Item = Get-Item $Link -Force

        if (-not (
            $Item.Attributes -band
            [IO.FileAttributes]::ReparsePoint
        )) {
            Fail "$Name`: $Skill não é Junction/Symlink"
            $ProfileOk = $false
        }

        if (-not (Test-Path $Source)) {
            Fail "$Name`: source compartilhada ausente: $Skill"
            $ProfileOk = $false
        }
    }

    $Plugins = Join-Path $Root "plugins"
    $SuperpowersPresent = $false

    if (Test-Path $Plugins) {
        $SuperpowersPresent = @(
            Get-ChildItem `
                $Plugins `
                -Recurse `
                -Force `
                -ErrorAction SilentlyContinue |
            Where-Object {
                $_.FullName -like
                    "*superpowers*$SuperpowersVersion*"
            }
        ).Count -gt 0
    }

    if (-not $SuperpowersPresent) {
        Fail "$Name`: Superpowers $SuperpowersVersion ausente"
        $ProfileOk = $false
    }

    if ($ProfileOk) {
        Ok $Name
    }
}


Section "Skills compartilhadas"

if (Test-Path $SharedSkills) {
    Ok $SharedSkills
}
else {
    Fail "Skills compartilhadas ausentes"
}


Section "Isolamento multi-projeto"

$Probe = Join-Path `
    ([IO.Path]::GetTempPath()) `
    ("codex-doctor-" + [guid]::NewGuid())

New-Item `
    -ItemType Directory `
    -Force `
    -Path $Probe |
    Out-Null

try {
    & git -C $Probe init -q

    if ($LASTEXITCODE -ne 0) {
        throw "git init falhou"
    }

    Set-Content `
        -Path (Join-Path $Probe "README.md") `
        -Value "# doctor"

    $BootstrapProject = Join-Path `
        $Kit `
        "bin\bootstrap-project.ps1"

    & $BootstrapProject $Probe *> $null

    if ($LASTEXITCODE -ne 0) {
        throw "bootstrap-project falhou"
    }

    $OldProjectRoot = $env:CODEX_PROJECT_ROOT
    $OldMcporter = $env:MCPORTER_CONFIG

    try {
        $env:CODEX_PROJECT_ROOT = $Probe
        Remove-Item Env:MCPORTER_CONFIG `
            -ErrorAction SilentlyContinue

        $Mcporter = Get-Command mcporter `
            -ErrorAction SilentlyContinue

        if (-not $Mcporter) {
            throw "mcporter não encontrado"
        }

        $Output = (& mcporter list 2>&1 | Out-String)

        if (
            $Output -match '2 healthy' -and
            $Output -notmatch '(?m)^-\s+dbhub\b'
        ) {
            Ok "projeto neutro = Serena + CodeGraph"
        }
        else {
            Fail "isolamento MCP do projeto neutro"

            $Output -split "`r?`n" |
                ForEach-Object {
                    if ($_){
                        Write-Host "      $_"
                    }
                }
        }
    }
    finally {
        if ($null -eq $OldProjectRoot) {
            Remove-Item Env:CODEX_PROJECT_ROOT `
                -ErrorAction SilentlyContinue
        }
        else {
            $env:CODEX_PROJECT_ROOT = $OldProjectRoot
        }

        if ($null -eq $OldMcporter) {
            Remove-Item Env:MCPORTER_CONFIG `
                -ErrorAction SilentlyContinue
        }
        else {
            $env:MCPORTER_CONFIG = $OldMcporter
        }
    }
}
catch {
    Fail "probe multi-projeto: $($_.Exception.Message)"
}
finally {
    if (Test-Path $Probe) {
        Remove-Item $Probe -Recurse -Force
    }
}


Section "Projeto atual"

$CurrentRootRaw = & git rev-parse --show-toplevel 2>$null

if ($LASTEXITCODE -eq 0 -and $CurrentRootRaw) {
    $CurrentRoot = $CurrentRootRaw.Trim()

    Ok "Git root: $CurrentRoot"

    if (Test-Path (Join-Path $CurrentRoot ".codex-local")) {
        Ok ".codex-local presente"
    }
    else {
        Warn ".codex-local ausente"
    }

    $ProjectMcporter = Join-Path `
        $CurrentRoot `
        "config\mcporter.json"

    if (Test-Path $ProjectMcporter) {
        try {
            Get-Content $ProjectMcporter -Raw |
                ConvertFrom-Json |
                Out-Null

            Ok "config/mcporter.json válido"
        }
        catch {
            Fail "config/mcporter.json inválido"
        }
    }
    else {
        Warn "projeto sem config/mcporter.json local"
    }

    if (Test-Path (Join-Path $CurrentRoot ".beads")) {
        Ok "Beads inicializado"
    }
    else {
        Warn "Beads não inicializado"
    }

    if (Test-Path (Join-Path $CurrentRoot "openspec")) {
        Ok "OpenSpec presente"
    }
    else {
        Warn "OpenSpec não presente"
    }
}
else {
    Warn "diretório atual não pertence a um repositório Git"
}


Section "Resumo"

Write-Host "  PASS: $Pass"
Write-Host "  WARN: $Warn"
Write-Host "  FAIL: $Fail"

Write-Host ""

if ($Fail -eq 0) {
    Write-Host "✅ Ambiente Codex Windows saudável"
    exit 0
}
else {
    Write-Host "❌ Ambiente Codex Windows possui falhas"
    exit 1
}
