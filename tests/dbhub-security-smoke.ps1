$ErrorActionPreference = "Stop"

$project = Join-Path `
    $env:RUNNER_TEMP `
    "codex-dbhub-smoke"

New-Item `
    -ItemType Directory `
    -Force `
    $project |
    Out-Null

git -C $project init -q

& ".\bin\bootstrap-project.ps1" `
    $project `
    --dbhub

if ($LASTEXITCODE -ne 0) {
    throw "bootstrap DBHub falhou"
}

$dbFile = Join-Path `
    $project `
    ".codex-local\dbhub-smoke.sqlite"

New-Item `
    -ItemType File `
    -Force `
    $dbFile |
    Out-Null

$env:CODEX_PROJECT_ROOT = $project

$dbPath = $dbFile -replace '\\', '/'
$env:DBHUB_DSN = "sqlite:///$dbPath"

$config = Join-Path `
    $project `
    "config\mcporter.json"

$globalMcporter = Join-Path `
    $HOME `
    ".mcporter\mcporter.json"

if (
    Select-String `
        -Path $globalMcporter `
        -Pattern '"dbhub"' `
        -Quiet
) {
    throw "DBHub vazou para configuração global"
}

$localConfig = Join-Path `
    $project `
    ".codex-local\dbhub\dbhub.toml"

if (-not (Test-Path $localConfig)) {
    throw "config DBHub local não encontrada: $localConfig"
}

if (-not (Test-Path $config)) {
    throw "config mcporter local não encontrada: $config"
}

foreach ($path in @($localConfig, $config)) {
    git -C $project check-ignore -q $path

    if ($LASTEXITCODE -ne 0) {
        throw "arquivo DBHub não está ignorado: $path"
    }
}

foreach ($path in @($localConfig, $config)) {
    if (
        Select-String `
            -Path $path `
            -SimpleMatch $env:DBHUB_DSN `
            -Quiet
    ) {
        throw "DBHUB_DSN foi persistido em $path"
    }
}

$McporterPs = Join-Path $HOME ".local\bin\mcporter.ps1"

if (-not (Test-Path $McporterPs)) {
    throw "wrapper mcporter.ps1 não encontrado"
}

function Invoke-DbHubSql {
    param([Parameter(Mandatory = $true)][string]$Sql)

    $payload = @{ sql = $Sql } | ConvertTo-Json -Compress

    $output = (
        & $McporterPs `
            call `
            dbhub.execute_sql `
            --args $payload `
            --config $config `
            2>&1 |
        Out-String
    )

    return [PSCustomObject]@{
        Output = $output
        Status = $LASTEXITCODE
    }
}

$oldNative = $PSNativeCommandUseErrorActionPreference
$PSNativeCommandUseErrorActionPreference = $false

try {
    $readResult = Invoke-DbHubSql -Sql "SELECT 1 AS ok"
    $read = $readResult.Output

    Write-Host $read

    if ($readResult.Status -ne 0) {
        throw "SELECT DBHub falhou"
    }

    if (
        $read -notmatch '"success":\s*true' -or
        $read -notmatch '"ok":\s*1'
    ) {
        throw "SELECT DBHub não retornou resultado esperado"
    }

    $hashBefore = (
        Get-FileHash `
            -Algorithm SHA256 `
            -Path $dbFile
    ).Hash

    function Assert-DbHubWriteDenied {
        param(
            [Parameter(Mandatory = $true)]
            [string]$Sql
        )

        $result = Invoke-DbHubSql -Sql $Sql
        $out = $result.Output
        $status = $result.Status

        Write-Host $out

        if ($status -eq 0) {
            throw "DBHub permitiu escrita: $Sql"
        }

        if ($out -notmatch 'READONLY_VIOLATION') {
            throw "DBHub não retornou READONLY_VIOLATION: $Sql"
        }
    }

    Assert-DbHubWriteDenied `
        'WITH payload(marker) AS (SELECT 1) INSERT INTO forbidden(marker) SELECT marker FROM payload'

    Assert-DbHubWriteDenied `
        'PRAGMA user_version = 4242'

    $hashAfter = (
        Get-FileHash `
            -Algorithm SHA256 `
            -Path $dbFile
    ).Hash

    if ($hashAfter -ne $hashBefore) {
        throw "DBHub alterou o arquivo SQLite em modo readonly"
    }
}
finally {
    $PSNativeCommandUseErrorActionPreference = $oldNative
}

$gitStatus = (& git -C $project status --short)

if ($gitStatus) {
    throw "runtime DBHub apareceu no Git"
}

Write-Host "DBHub Windows security smoke passou"
