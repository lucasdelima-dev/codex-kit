$ErrorActionPreference = "Stop"

if (Get-Variable `
    PSNativeCommandUseErrorActionPreference `
    -ErrorAction SilentlyContinue) {
    $PSNativeCommandUseErrorActionPreference = $true
}

. (Join-Path $PSScriptRoot "common.ps1")

$Versions = Read-EnvManifest (Join-Path $Kit "manifests\tools.env")

$NodeVersion          = $Versions["NODE24_VERSION"]
$UvVersion            = $Versions["UV_VERSION"]
$CodexVersion         = $Versions["CODEX_VERSION"]
$RtkVersion           = $Versions["RTK_VERSION"]
$OpenSpecVersion      = $Versions["OPENSPEC_VERSION"]
$CodeGraphVersion     = $Versions["CODEGRAPH_VERSION"]
$SerenaVersion        = $Versions["SERENA_VERSION"]
$McporterVersion      = $Versions["MCPORTER_VERSION"]
$Ctx7Version          = $Versions["CTX7_VERSION"]
$BeadsVersion         = $Versions["BEADS_VERSION"]
$RepomixVersion       = $Versions["REPOMIX_VERSION"]
$SemgrepVersion       = $Versions["SEMGREP_VERSION"]
$AgentBrowserVersion  = $Versions["AGENT_BROWSER_VERSION"]
$PlaywrightVersion    = $Versions["PLAYWRIGHT_CLI_VERSION"]
$ChromeVersion        = $Versions["CHROME_DEVTOOLS_VERSION"]
$DbhubVersion         = $Versions["DBHUB_VERSION"]
$UiUxVersion          = $Versions["UI_UX_PRO_MAX_VERSION"]
$OpenDesignVersion    = $Versions["OPENDESIGN_VERSION"]
$OpenDesignTag        = $Versions["OPENDESIGN_TAG"]
$OpenDesignCommit     = $Versions["OPENDESIGN_COMMIT"]
$PnpmVersion          = $Versions["PNPM_VERSION"]

$NpmPrefix = Join-Path $LocalRoot "npm"
$NodeDir   = Join-Path $OptRoot "node-v$NodeVersion"
$Node24    = Join-Path $OptRoot "node24"

Ensure-Directory $LocalRoot
Ensure-Directory $BinRoot
Ensure-Directory $OptRoot
Ensure-Directory $ShareRoot
Ensure-Directory $NpmPrefix

function Get-PackageVersion {
    param([string]$PackageJson)

    if (-not (Test-Path $PackageJson)) {
        return $null
    }

    try {
        return (Get-Content $PackageJson -Raw | ConvertFrom-Json).version
    }
    catch {
        return $null
    }
}

function Ensure-NpmPackage {
    param(
        [string]$Package,
        [string]$Version,
        [string]$AllowScripts = "",
        [string]$RequiredFile = ""
    )

    $PackagePath = ($Package -split "/") -join [IO.Path]::DirectorySeparatorChar
    $Json = Join-Path $NpmPrefix "node_modules\$PackagePath\package.json"
    $Current = Get-PackageVersion $Json

    if (
        $Current -eq $Version -and
        (-not $RequiredFile -or (Test-Path $RequiredFile))
    ) {
        Write-Ok "$Package@$Version"
        return
    }

    Write-Step "Instalando $Package@$Version"

    $Args = @("install", "-g", "--prefix", $NpmPrefix)

    if ($AllowScripts) {
        $Args += "--allow-scripts=$AllowScripts"
    }

    $Args += "$Package@$Version"

    & $script:NpmCmd @Args

    if ($LASTEXITCODE -ne 0) {
        throw "Falha instalando $Package@$Version"
    }

    if ($RequiredFile -and -not (Test-Path $RequiredFile)) {
        throw "Binário esperado ausente: $RequiredFile"
    }
}

function Ensure-UvTool {
    param(
        [string]$Package,
        [string]$Version
    )

    $Output = & $script:UvExe tool list 2>$null
    $Pattern = "^$([regex]::Escape($Package))\s+v?([0-9.]+)"
    $Current = $null

    foreach ($Line in $Output) {
        if ($Line -match $Pattern) {
            $Current = $Matches[1]
            break
        }
    }

    if ($Current -eq $Version) {
        Write-Ok "$Package@$Version"
        return
    }

    Write-Step "Instalando $Package==$Version"

    & $script:UvExe tool install --force "$Package==$Version"

    if ($LASTEXITCODE -ne 0) {
        throw "Falha instalando $Package==$Version"
    }
}



function Ensure-AgentBrowser {
    $Root = Join-Path $NpmPrefix "node_modules\agent-browser"
    $Json = Join-Path $Root "package.json"
    $Current = Get-PackageVersion $Json

    $Asset = "agent-browser-win32-x64.exe"
    $Target = Join-Path $Root "bin\$Asset"
    $Expected = $Versions["AGENT_BROWSER_SHA256_WINDOWS_X64"]

    if ($Current -ne $AgentBrowserVersion) {
        Write-Step "Instalando agent-browser sem postinstall"

        & $script:NpmCmd install `
            -g `
            --prefix $NpmPrefix `
            --ignore-scripts `
            "agent-browser@$AgentBrowserVersion"

        if ($LASTEXITCODE -ne 0) {
            throw "Falha instalando agent-browser."
        }
    }

    if (-not (Test-Path (Join-Path $Root "bin\agent-browser.js"))) {
        throw "Wrapper do agent-browser ausente."
    }

    $Actual = ""

    if (Test-Path $Target) {
        $Actual = (
            Get-FileHash $Target -Algorithm SHA256
        ).Hash.ToLowerInvariant()
    }

    if ($Actual -ne $Expected) {
        $Tmp = Join-Path `
            ([IO.Path]::GetTempPath()) `
            ("codex-agent-browser-" + [guid]::NewGuid().ToString("N"))

        New-Item -ItemType Directory -Force $Tmp | Out-Null

        try {
            $Download = Join-Path $Tmp $Asset
            $Url = "https://github.com/vercel-labs/agent-browser/releases/download/v$AgentBrowserVersion/$Asset"

            Invoke-WebRequest $Url -OutFile $Download

            $DownloadedHash = (
                Get-FileHash $Download -Algorithm SHA256
            ).Hash.ToLowerInvariant()

            if ($DownloadedHash -ne $Expected) {
                throw "SHA-256 inválido do agent-browser."
            }

            Copy-Item $Download $Target -Force
        }
        finally {
            if (Test-Path $Tmp) {
                Remove-Item $Tmp -Recurse -Force
            }
        }
    }

    $FinalHash = (
        Get-FileHash $Target -Algorithm SHA256
    ).Hash.ToLowerInvariant()

    if ($FinalHash -ne $Expected) {
        throw "Verificação final do agent-browser falhou."
    }

    Write-Ok "agent-browser@$AgentBrowserVersion SHA-256 validado"
}


Write-Step "Plataforma"

if (-not $IsWindows -and $PSVersionTable.PSEdition -eq "Core") {
    throw "Adapter Windows executado fora do Windows."
}

$Arch = [System.Runtime.InteropServices.RuntimeInformation]::OSArchitecture.ToString()

Write-Host "    SO:         Windows"
Write-Host "    Arquitetura: $Arch"

if ($Arch -ne "X64") {
    throw "Windows nativo v1 suporta x64. Para ARM64 use WSL2/Linux ARM64."
}


Write-Step "Dependências básicas"

if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    if (Get-Command winget -ErrorAction SilentlyContinue) {
        Write-Host "    Git ausente; instalando via winget..."

        winget install `
            --id Git.Git `
            --exact `
            --accept-package-agreements `
            --accept-source-agreements

        if ($LASTEXITCODE -ne 0) {
            throw "Falha instalando Git."
        }

        $env:Path = "$env:ProgramFiles\Git\cmd;$env:Path"
    }
    else {
        throw "Git ausente e winget indisponível."
    }
}

Write-Ok "Git"


Write-Step "Node $NodeVersion"

$NodeExe = Join-Path $NodeDir "node.exe"
$CurrentNode = $null

if (Test-Path $NodeExe) {
    $CurrentNode = & $NodeExe --version
}

if ($CurrentNode -ne "v$NodeVersion") {
    $Tmp = Join-Path ([IO.Path]::GetTempPath()) ("codex-node-" + [guid]::NewGuid())
    New-Item -ItemType Directory -Force -Path $Tmp | Out-Null

    $Archive = "node-v$NodeVersion-win-x64.zip"
    $Base = "https://nodejs.org/dist/v$NodeVersion"

    $ArchivePath = Join-Path $Tmp $Archive
    $Checksums = Join-Path $Tmp "SHASUMS256.txt"

    Invoke-WebRequest "$Base/$Archive" -OutFile $ArchivePath
    Invoke-WebRequest "$Base/SHASUMS256.txt" -OutFile $Checksums

    $ChecksumLine = Get-Content $Checksums |
        Where-Object { $_ -match "\s+$([regex]::Escape($Archive))$" } |
        Select-Object -First 1

    if (-not $ChecksumLine) {
        throw "Checksum do Node não encontrado."
    }

    $Expected = ($ChecksumLine -split "\s+")[0].ToLowerInvariant()
    $Actual = (Get-FileHash $ArchivePath -Algorithm SHA256).Hash.ToLowerInvariant()

    if ($Expected -ne $Actual) {
        throw "Checksum do Node inválido."
    }

    $Extract = Join-Path $Tmp "extract"
    Expand-Archive $ArchivePath -DestinationPath $Extract

    $Extracted = Join-Path $Extract "node-v$NodeVersion-win-x64"

    if (Test-Path $NodeDir) {
        $Backup = "$NodeDir.broken-$(Get-Date -Format yyyyMMddHHmmss)"
        Move-Item $NodeDir $Backup
    }

    Move-Item $Extracted $NodeDir

    Remove-Item $Tmp -Recurse -Force
}

if (-not (Test-Path $Node24)) {
    New-Item `
        -ItemType Junction `
        -Path $Node24 `
        -Target $NodeDir |
        Out-Null
}
else {
    $Item = Get-Item $Node24 -Force

    if (-not ($Item.Attributes -band [IO.FileAttributes]::ReparsePoint)) {
        throw "$Node24 existe, mas não é Junction/Symlink."
    }
}

$script:NodeExe = Join-Path $Node24 "node.exe"
$script:NpmCmd  = Join-Path $Node24 "npm.cmd"

Write-Ok (& $NodeExe --version)


Write-Step "PATH do usuário"

$RequiredPaths = @(
    $BinRoot,
    $NpmPrefix,
    $Node24
)

$UserPath = [Environment]::GetEnvironmentVariable("Path", "User")

if (-not $UserPath) {
    $UserPath = ""
}

$UserParts = @($UserPath -split ";" | Where-Object { $_ })

foreach ($Entry in $RequiredPaths) {
    if ($UserParts -notcontains $Entry) {
        $UserParts += $Entry
    }
}

$NewUserPath = ($UserParts -join ";")

[Environment]::SetEnvironmentVariable(
    "Path",
    $NewUserPath,
    "User"
)

$env:Path = "$BinRoot;$NpmPrefix;$Node24;$env:Path"

Write-Ok "PATH"


Write-Step "uv $UvVersion"

$script:UvExe = Join-Path $BinRoot "uv.exe"
$UvXExe = Join-Path $BinRoot "uvx.exe"
$UvExpected = $Versions["UV_SHA256_WINDOWS_X64"]
$CurrentUv = $null

if (Test-Path $UvExe) {
    $RawUv = & $UvExe --version

    if ($RawUv -match '^uv\s+([0-9.]+)') {
        $CurrentUv = $Matches[1]
    }
}

$CurrentUvx = $null

if (Test-Path $UvXExe) {
    $RawUvx = & $UvXExe --version

    if ($RawUvx -match '^(?:uv|uvx)\s+([0-9.]+)') {
        $CurrentUvx = $Matches[1]
    }
}

if ($CurrentUv -ne $UvVersion -or $CurrentUvx -ne $UvVersion) {
    $Tmp = Join-Path `
        ([IO.Path]::GetTempPath()) `
        ("codex-uv-" + [guid]::NewGuid().ToString("N"))

    New-Item -ItemType Directory -Force $Tmp | Out-Null

    try {
        $Asset = "uv-x86_64-pc-windows-msvc.zip"
        $Base = "https://github.com/astral-sh/uv/releases/download/$UvVersion"

        $Archive = Join-Path $Tmp $Asset
        $Extract = Join-Path $Tmp "extract"

        Invoke-WebRequest "$Base/$Asset" -OutFile $Archive

        $Actual = (
            Get-FileHash $Archive -Algorithm SHA256
        ).Hash.ToLowerInvariant()

        if ($Actual -ne $UvExpected) {
            throw "SHA-256 do uv inválido: $Asset"
        }

        Expand-Archive $Archive -DestinationPath $Extract

        $FoundUv = Get-ChildItem `
            $Extract -Recurse -File -Filter "uv.exe" |
            Select-Object -First 1

        $FoundUvx = Get-ChildItem `
            $Extract -Recurse -File -Filter "uvx.exe" |
            Select-Object -First 1

        if (-not $FoundUv -or -not $FoundUvx) {
            throw "Binários uv/uvx ausentes no release."
        }

        Copy-Item $FoundUv.FullName $UvExe -Force
        Copy-Item $FoundUvx.FullName $UvXExe -Force
    }
    finally {
        if (Test-Path $Tmp) {
            Remove-Item $Tmp -Recurse -Force
        }
    }
}

Write-Ok (& $UvExe --version)


$env:UV_TOOL_BIN_DIR = $BinRoot
$env:UV_TOOL_DIR = Join-Path $ShareRoot "uv\tools"

Ensure-Directory $env:UV_TOOL_DIR


Write-Step "Ferramentas npm"

Ensure-NpmPackage "@openai/codex"          $CodexVersion
Ensure-NpmPackage "@fission-ai/openspec"  $OpenSpecVersion
Ensure-NpmPackage "@lzehrung/codegraph"   $CodeGraphVersion
Ensure-NpmPackage "ctx7"                  $Ctx7Version
Ensure-NpmPackage "repomix"               $RepomixVersion
Ensure-AgentBrowser
Ensure-NpmPackage "@playwright/cli"       $PlaywrightVersion
Ensure-NpmPackage "chrome-devtools-mcp"   $ChromeVersion
Ensure-NpmPackage "@bytebase/dbhub"       $DbhubVersion
Ensure-NpmPackage "ui-ux-pro-max-cli"     $UiUxVersion


Write-Step "Ferramentas uv"

Ensure-UvTool "serena-agent" $SerenaVersion
Ensure-UvTool "semgrep"      $SemgrepVersion


Write-Step "mcporter"

$McporterRoot = Join-Path $ShareRoot "mcporter"
Ensure-Directory $McporterRoot

$McporterJson = Join-Path $McporterRoot "node_modules\mcporter\package.json"
$McporterCurrent = Get-PackageVersion $McporterJson

if ($McporterCurrent -ne $McporterVersion) {
    & $NpmCmd install `
        --prefix $McporterRoot `
        "mcporter@$McporterVersion"

    if ($LASTEXITCODE -ne 0) {
        throw "Falha instalando mcporter."
    }
}
else {
    Write-Ok "mcporter@$McporterVersion"
}


Write-Step "RTK"

$RtkExe = Join-Path $BinRoot "rtk.exe"
$RtkCurrent = $null

if (Test-Path $RtkExe) {
    $RawRtk = & $RtkExe --version 2>$null

    if ($RawRtk -match '([0-9]+\.[0-9]+\.[0-9]+)') {
        $RtkCurrent = $Matches[1]
    }
}

if ($RtkCurrent -ne $RtkVersion) {
    $Tmp = Join-Path ([IO.Path]::GetTempPath()) ("codex-rtk-" + [guid]::NewGuid())
    New-Item -ItemType Directory -Force -Path $Tmp | Out-Null

    $Asset = "rtk-x86_64-pc-windows-msvc.zip"
    $Base = "https://github.com/rtk-ai/rtk/releases/download/v$RtkVersion"

    $Archive = Join-Path $Tmp $Asset
    $Checksums = Join-Path $Tmp "checksums.txt"

    Invoke-WebRequest "$Base/$Asset" -OutFile $Archive
    Invoke-WebRequest "$Base/checksums.txt" -OutFile $Checksums

    $ChecksumLine = Get-Content $Checksums |
        Where-Object { $_ -match "\s+$([regex]::Escape($Asset))$" } |
        Select-Object -First 1

    if (-not $ChecksumLine) {
        throw "Checksum do RTK não encontrado."
    }

    $Expected = ($ChecksumLine -split "\s+")[0].ToLowerInvariant()
    $Actual = (Get-FileHash $Archive -Algorithm SHA256).Hash.ToLowerInvariant()

    if ($Expected -ne $Actual) {
        throw "Checksum do RTK inválido."
    }

    $Extract = Join-Path $Tmp "extract"
    Expand-Archive $Archive -DestinationPath $Extract

    $Found = Get-ChildItem `
        $Extract `
        -Recurse `
        -Filter "rtk.exe" |
        Select-Object -First 1

    if (-not $Found) {
        throw "rtk.exe não encontrado no release."
    }

    Copy-Item $Found.FullName $RtkExe -Force

    Remove-Item $Tmp -Recurse -Force
}
else {
    Write-Ok "rtk@$RtkVersion"
}



Write-Step "Beads $BeadsVersion"

$BdExe = Join-Path $BinRoot "bd.exe"
$BdCurrent = $null

if (Test-Path $BdExe) {
    $RawBd = & $BdExe --version 2>$null

    if ($RawBd -match '([0-9]+\.[0-9]+\.[0-9]+)') {
        $BdCurrent = $Matches[1]
    }
}

if ($BdCurrent -ne $BeadsVersion) {
    $Tmp = Join-Path `
        ([IO.Path]::GetTempPath()) `
        ("codex-beads-" + [guid]::NewGuid())

    $Extract = Join-Path $Tmp "extract"
    New-Item -ItemType Directory -Force $Extract | Out-Null

    $Asset = "beads_${BeadsVersion}_windows_amd64.zip"
    $Base = "https://github.com/gastownhall/beads/releases/download/v$BeadsVersion"

    $Archive = Join-Path $Tmp $Asset
    $Checksums = Join-Path $Tmp "checksums.txt"

    Invoke-WebRequest "$Base/$Asset" -OutFile $Archive
    Invoke-WebRequest "$Base/checksums.txt" -OutFile $Checksums

    $ChecksumLine = Get-Content $Checksums |
        Where-Object {
            $parts = $_ -split '\s+'
            $name = $parts[-1].TrimStart('*')
            $name -eq $Asset
        } |
        Select-Object -First 1

    if (-not $ChecksumLine) {
        throw "Checksum do Beads não encontrado."
    }

    $Expected = ($ChecksumLine -split '\s+')[0].ToLowerInvariant()
    $Actual = (Get-FileHash $Archive -Algorithm SHA256).Hash.ToLowerInvariant()

    if ($Expected -ne $Actual) {
        throw "Checksum do Beads inválido."
    }

    Expand-Archive $Archive -DestinationPath $Extract

    $Found = Get-ChildItem $Extract -Recurse -Filter "bd.exe" |
        Select-Object -First 1

    if (-not $Found) {
        throw "bd.exe não encontrado no release."
    }

    Copy-Item $Found.FullName $BdExe -Force
    Remove-Item $Tmp -Recurse -Force
}
else {
    Write-Ok "Beads $BeadsVersion"
}

Write-Step "pnpm para OpenDesign"

$Pnpm = Join-Path $NodeDir "pnpm.cmd"
$PnpmCurrent = $null

if (Test-Path $Pnpm) {
    $PnpmCurrent = & $Pnpm --version
}

if ($PnpmCurrent -ne $PnpmVersion) {
    & $NpmCmd install `
        -g `
        --prefix $NodeDir `
        "pnpm@$PnpmVersion"

    if ($LASTEXITCODE -ne 0) {
        throw "Falha instalando pnpm."
    }
}
else {
    Write-Ok "pnpm@$PnpmVersion"
}


Write-Step "OpenDesign"

$OdRoot = Join-Path $ShareRoot "open-design-$OpenDesignVersion"
$OdCli  = Join-Path $OdRoot "apps\daemon\dist\cli.js"

if (-not (Test-Path $OdRoot)) {
    & git clone `
        --depth 1 `
        --branch $OpenDesignTag `
        https://github.com/nexu-io/open-design.git `
        $OdRoot

    if ($LASTEXITCODE -ne 0) {
        throw "Falha clonando OpenDesign."
    }
}

$OdHead = & git -C $OdRoot rev-parse HEAD 2>$null

if ($LASTEXITCODE -ne 0 -or "$OdHead".Trim() -ne $OpenDesignCommit) {
    throw "OpenDesign não corresponde ao commit fixado."
}

if (-not (Test-Path $OdCli)) {
    Push-Location $OdRoot

    try {
        $env:Path = "$Node24;$env:Path"
        $env:NEXT_TELEMETRY_DISABLED = "1"

        & $Pnpm install --frozen-lockfile

        if ($LASTEXITCODE -ne 0) {
            throw @"
OpenDesign: pnpm install falhou.

No Windows nativo com Node 24, dependências nativas como better-sqlite3
podem precisar do Visual Studio 2022 Build Tools com workload C++ e Python.

Após instalar os pré-requisitos, execute bootstrap-machine novamente.
"@
        }

        & $Pnpm --filter "@open-design/daemon" build

        if ($LASTEXITCODE -ne 0) {
            throw "Falha no build do daemon OpenDesign."
        }

        $OldOptions = $env:NODE_OPTIONS
        $env:NODE_OPTIONS = "--max-old-space-size=4096"

        try {
            & $Pnpm --filter "@open-design/web" build

            if ($LASTEXITCODE -ne 0) {
                throw "Falha no build web do OpenDesign."
            }
        }
        finally {
            $env:NODE_OPTIONS = $OldOptions
        }
    }
    finally {
        Pop-Location
    }
}
else {
    Write-Ok "OpenDesign $OpenDesignVersion"
}


Write-Step "Wrappers Windows"

$WindowsWrappers = Join-Path $Kit "wrappers\windows"

foreach ($Name in @(
    "codex-code",
    "chrome-devtools",
    "mcporter",
    "od"
)) {
    $Source = Join-Path $WindowsWrappers "$Name.ps1"
    $DestPs = Join-Path $BinRoot "$Name.ps1"
    $DestCmd = Join-Path $BinRoot "$Name.cmd"

    if (-not (Test-Path $Source)) {
        throw "Wrapper ausente: $Source"
    }

    Copy-Item $Source $DestPs -Force

    $CmdText = @"
@echo off
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%USERPROFILE%\.local\bin\$Name.ps1" %*
"@

    Set-Content `
        -Path $DestCmd `
        -Value $CmdText `
        -Encoding ASCII
}

Write-Ok "wrappers"


Write-Step "Skills compartilhadas"

Ensure-Directory $SharedSkills

Copy-Item `
    (Join-Path $Kit "skills\*") `
    $SharedSkills `
    -Recurse `
    -Force

Write-Ok "Skills"


Write-Step "UI/UX Pro Max runtime"

$Uipro = Join-Path $NpmPrefix "uipro.cmd"

if (-not (Test-Path $Uipro)) {
    throw "UI/UX Pro Max CLI não encontrado: $Uipro"
}

$TmpUiux = Join-Path `
    ([IO.Path]::GetTempPath()) `
    ("codex-uiux-" + [guid]::NewGuid())

New-Item `
    -ItemType Directory `
    -Force `
    -Path $TmpUiux |
    Out-Null

try {
    Push-Location $TmpUiux

    try {
        & $Uipro init `
            --ai codex `
            --offline `
            --force

        if ($LASTEXITCODE -ne 0) {
            throw "Falha gerando Skill UI/UX Pro Max."
        }
    }
    finally {
        Pop-Location
    }

    $GeneratedUiux = Join-Path `
        $TmpUiux `
        ".agents\skills\ui-ux-pro-max"

    if (-not (Test-Path $GeneratedUiux)) {
        throw "Skill UI/UX Pro Max não foi gerada no local esperado."
    }

    $UiuxDestination = Join-Path `
        $SharedSkills `
        "ui-ux-pro-max"

    if (Test-Path $UiuxDestination) {
        Remove-Item `
            $UiuxDestination `
            -Recurse `
            -Force
    }

    Copy-Item `
        $GeneratedUiux `
        $UiuxDestination `
        -Recurse `
        -Force
}
finally {
    if (Test-Path $TmpUiux) {
        Remove-Item `
            $TmpUiux `
            -Recurse `
            -Force
    }
}

Write-Ok "UI/UX Pro Max $UiUxVersion"

Write-Step "mcporter global"

Ensure-Directory $McporterHome

Copy-Item `
    (Join-Path $Kit "templates\mcporter\global.json") `
    (Join-Path $McporterHome "mcporter.json") `
    -Force

Write-Ok "mcporter.json"


Write-Step "Diretórios runtime"

Ensure-Directory (Join-Path $HOME ".serena")
Ensure-Directory (Join-Path $HOME ".semgrep")


Write-Step "VS Code"

$Code = Get-Command code -ErrorAction SilentlyContinue

if ($Code) {
    $Extensions = & $Code.Source --list-extensions

    if ($Extensions -contains "openai.chatgpt") {
        Write-Ok "extensão openai.chatgpt"
    }
    else {
        & $Code.Source --install-extension openai.chatgpt

        if ($LASTEXITCODE -eq 0) {
            Write-Ok "extensão openai.chatgpt instalada"
        }
        else {
            Write-Warning "Não foi possível instalar openai.chatgpt."
        }
    }
}
else {
    Write-Warning "VS Code CLI 'code' não encontrado."
}


Write-Step "Validação"

& $NodeExe --version
& (Join-Path $NpmPrefix "codex.cmd") --version
& $RtkExe --version
& (Join-Path $NpmPrefix "openspec.cmd") --version
& (Join-Path $NpmPrefix "codegraph.cmd") --version
& (Join-Path $BinRoot "serena.exe") --version
& (Join-Path $BinRoot "mcporter.ps1") --version
& (Join-Path $NpmPrefix "ctx7.cmd") --version
& $BdExe --version
& (Join-Path $NpmPrefix "repomix.cmd") --version
& (Join-Path $BinRoot "semgrep.exe") --version
& (Join-Path $NpmPrefix "agent-browser.cmd") --version
& (Join-Path $NpmPrefix "playwright-cli.cmd") --version
& (Join-Path $BinRoot "chrome-devtools.ps1") --version
& (Join-Path $BinRoot "od.ps1") --help | Out-Null

Write-Host ""
Write-Host "================================================"
Write-Host " bootstrap-machine Windows concluído com sucesso"
Write-Host "================================================"
