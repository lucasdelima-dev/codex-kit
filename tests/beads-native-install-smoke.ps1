$ErrorActionPreference = "Stop"

$Kit = Split-Path -Parent $PSScriptRoot
$Machine = Join-Path $Kit "platform\windows\machine.ps1"
$Source = Get-Content $Machine -Raw

$StartMarker = 'Write-Step "Beads $BeadsVersion"'
$EndMarker = 'Write-Step "pnpm para OpenDesign"'

$Start = $Source.IndexOf($StartMarker, [StringComparison]::Ordinal)
$End = $Source.IndexOf($EndMarker, [StringComparison]::Ordinal)

if ($Start -lt 0 -or $End -le $Start) {
    throw "Bloco de instalação do Beads não encontrado."
}

$InstallBlock = [ScriptBlock]::Create(
    $Source.Substring($Start, $End - $Start)
)

$Tmp = Join-Path ([IO.Path]::GetTempPath()) (
    "codex-beads-native-" + [guid]::NewGuid().ToString("N")
)

$script:Requests = 0

function Write-Step {
    param([string]$Message)
    Write-Host "==> $Message"
}

function Write-Ok {
    param([string]$Message)
    Write-Host "    OK: $Message"
}

# Substitui a chamada de rede por cópias de fixtures locais.
function Invoke-WebRequest {
    param(
        [Parameter(Position = 0)]
        [string]$Uri,
        [string]$OutFile
    )

    $script:Requests++

    if ($Uri -match '/checksums\.txt$') {
        Copy-Item $script:FixtureChecksums $OutFile
    }
    elseif ($Uri -match '/beads_1\.3\.1_windows_amd64\.zip$') {
        Copy-Item $script:FixtureArchive $OutFile
    }
    else {
        throw "Download inesperado no teste: $Uri"
    }
}

try {
    New-Item -ItemType Directory -Force $Tmp | Out-Null

    $FixtureDir = Join-Path $Tmp "fixture"
    New-Item -ItemType Directory -Force $FixtureDir | Out-Null

    # Executável nativo PE de teste, sem dependências externas.
    $SystemExe = Join-Path $env:WINDIR "System32\whoami.exe"

    if (-not (Test-Path $SystemExe)) {
        throw "Fixture PE do Windows não encontrada."
    }

    $FixtureBd = Join-Path $FixtureDir "bd.exe"
    Copy-Item $SystemExe $FixtureBd

    $script:FixtureArchive = Join-Path $Tmp (
        "beads_1.3.1_windows_amd64.zip"
    )

    Compress-Archive `
        -Path $FixtureBd `
        -DestinationPath $script:FixtureArchive `
        -Force

    $CorrectHash = (
        Get-FileHash $script:FixtureArchive -Algorithm SHA256
    ).Hash.ToLowerInvariant()

    $script:FixtureChecksums = Join-Path $Tmp "checksums.txt"

    "$CorrectHash  beads_1.3.1_windows_amd64.zip" |
        Set-Content $script:FixtureChecksums

    $BeadsVersion = "1.3.1"

    Write-Host "=== 1. Instalação nativa simulada ==="

    $BinRoot = Join-Path $Tmp "instalacao"
    New-Item -ItemType Directory -Force $BinRoot | Out-Null

    $Versions = @{
        BEADS_SHA256_WINDOWS_AMD64 = $CorrectHash
    }

    $script:Requests = 0
    & $InstallBlock

    $Installed = Join-Path $BinRoot "bd.exe"

    if (-not (Test-Path $Installed)) {
        throw "Executável nativo não foi instalado."
    }

    if (
        (Get-FileHash $Installed).Hash -ne
        (Get-FileHash $FixtureBd).Hash
    ) {
        throw "Executável instalado difere da fixture."
    }

    if ($script:Requests -ne 2) {
        throw "Quantidade inesperada de downloads simulados."
    }

    Write-Host "✅ Executável PE instalado com checksum válido"

    Write-Host "=== 2. Rejeição de hash divergente ==="

    $BinRoot = Join-Path $Tmp "hash-invalido"
    New-Item -ItemType Directory -Force $BinRoot | Out-Null

    $Versions = @{
        BEADS_SHA256_WINDOWS_AMD64 = ("0" * 64)
    }

    $Rejected = $false

    try {
        & $InstallBlock
    }
    catch {
        if ($_.Exception.Message -notmatch "Checksum do Beads inválido") {
            throw
        }
        $Rejected = $true
    }

    if (-not $Rejected) {
        throw "Checksum inválido foi aceito."
    }

    if (Test-Path (Join-Path $BinRoot "bd.exe")) {
        throw "Executável foi instalado apesar do hash inválido."
    }

    Write-Host "✅ Download adulterado rejeitado"

    Write-Host "=== 3. Arquivo não nativo preservado ==="

    $BinRoot = Join-Path $Tmp "nao-nativo"
    New-Item -ItemType Directory -Force $BinRoot | Out-Null

    $Existing = Join-Path $BinRoot "bd.exe"
    "conteudo original preservar" | Set-Content $Existing

    $OriginalHash = (Get-FileHash $Existing).Hash
    $Versions = @{
        BEADS_SHA256_WINDOWS_AMD64 = $CorrectHash
    }

    $script:Requests = 0
    $Rejected = $false

    try {
        & $InstallBlock
    }
    catch {
        if ($_.Exception.Message -notmatch "não é um executável PE") {
            throw
        }
        $Rejected = $true
    }

    if (-not $Rejected) {
        throw "Arquivo não nativo foi aceito."
    }

    if ((Get-FileHash $Existing).Hash -ne $OriginalHash) {
        throw "Arquivo original foi modificado."
    }

    if ($script:Requests -ne 0) {
        throw "Ocorreu download antes da rejeição."
    }

    Write-Host "✅ Arquivo original preservado"
    Write-Host "✅ Nenhum download indevido"

    Write-Host "✅ Beads Windows native install smoke passou"
}
finally {
    if (Test-Path $Tmp) {
        Remove-Item $Tmp -Recurse -Force
    }
}
