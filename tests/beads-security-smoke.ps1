$ErrorActionPreference = "Stop"

$Kit = Split-Path -Parent $PSScriptRoot
$Bootstrap = Join-Path $Kit "bin\windows\bootstrap-project.ps1"
$Bd = Join-Path $HOME ".local\bin\bd.exe"

if (-not (Test-Path $Bd)) {
    throw "Beads não encontrado: $Bd"
}

$Tmp = Join-Path ([IO.Path]::GetTempPath()) (
    "codex-beads-smoke-" + [guid]::NewGuid().ToString("N")
)

$A = Join-Path $Tmp "projeto-a"
$B = Join-Path $Tmp "projeto-b"

$OldCI = $env:CI
$OldMetrics = $env:BD_DISABLE_METRICS

function Invoke-BdProject {
    param(
        [string]$Project,
        [string[]]$Arguments
    )

    Push-Location $Project
    try {
        $Output = & $Bd @Arguments

        if ($LASTEXITCODE -ne 0) {
            throw "Falha no Beads: $($Arguments -join ' ')"
        }

        return ($Output | Out-String).Trim()
    }
    finally {
        Pop-Location
    }
}

try {
    $env:CI = "true"
    $env:BD_DISABLE_METRICS = "1"

    foreach ($Project in @($A, $B)) {
        New-Item -ItemType Directory -Force $Project | Out-Null

        & git -C $Project init -q
        if ($LASTEXITCODE -ne 0) { throw "git init falhou" }

        "# Instrucoes originais" |
            Set-Content (Join-Path $Project "AGENTS.md")

        "node_modules/" |
            Set-Content (Join-Path $Project ".gitignore")

        & git -C $Project add AGENTS.md .gitignore
        if ($LASTEXITCODE -ne 0) { throw "git add falhou" }

        & git -C $Project `
            -c "user.name=Codex Kit Smoke" `
            -c "user.email=smoke@example.invalid" `
            commit -qm baseline

        if ($LASTEXITCODE -ne 0) { throw "git commit falhou" }

        & git -C $Project config core.hooksPath hooks-existentes
        if ($LASTEXITCODE -ne 0) { throw "Git config falhou" }
    }

    & git -C $B config beads.role contributor
    if ($LASTEXITCODE -ne 0) { throw "Git role falhou" }

    $Hashes = @{}

    foreach ($Project in @($A, $B)) {
        $Hashes[$Project] = @{
            Agents = (Get-FileHash (
                Join-Path $Project "AGENTS.md"
            )).Hash
            Ignore = (Get-FileHash (
                Join-Path $Project ".gitignore"
            )).Hash
        }

        Write-Host "=== Bootstrap: $(Split-Path $Project -Leaf) ==="

        & $Bootstrap -Path $Project -Beads

        $ConfigFile = Join-Path $Project ".beads\config.yaml"

        if (-not (Test-Path $ConfigFile)) {
            throw "Configuração Beads ausente"
        }

        $Config = Get-Content $ConfigFile -Raw

        if ($Config -notmatch '(?m)^no-git-ops:\s*true\s*$') {
            throw "no-git-ops não configurado localmente"
        }

        $GitAdd = Invoke-BdProject $Project @(
            "config", "get", "export.git-add"
        )

        if ($GitAdd -ne "false") {
            throw "export.git-add não está desativado"
        }

        & git -C $Project check-ignore -q ".beads/config.yaml"

        if ($LASTEXITCODE -ne 0) {
            throw ".beads/config.yaml não está ignorado"
        }

        foreach ($Check in @(
            @{ File = "AGENTS.md"; Key = "Agents" },
            @{ File = ".gitignore"; Key = "Ignore" }
        )) {
            $Actual = (Get-FileHash (
                Join-Path $Project $Check.File
            )).Hash

            if ($Actual -ne $Hashes[$Project][$Check.Key]) {
                throw "Arquivo original alterado: $($Check.File)"
            }
        }

        $Hooks = & git -C $Project config --get core.hooksPath

        if ($Hooks -ne "hooks-existentes") {
            throw "Hooks Git alterados"
        }

        $Status = & git -C $Project status --porcelain

        if ($Status) {
            throw "Git deixou de estar limpo: $Status"
        }

        Write-Host "✅ Stealth, Git e arquivos preservados"
    }

    $RoleA = & git -C $A config --get beads.role
    $RoleB = & git -C $B config --get beads.role

    if ($RoleA -ne "maintainer" -or $RoleB -ne "contributor") {
        throw "Funções Git alteradas"
    }

    Write-Host "✅ Funções Git preservadas"

    & git -C $B config beads.role maintainer
    if ($LASTEXITCODE -ne 0) { throw "Git role falhou" }

    $IdA = Invoke-BdProject $A @(
        "create", "--silent", "AUDIT-BEADS-ALPHA-ONLY"
    )

    $IdB = Invoke-BdProject $B @(
        "create", "--silent", "AUDIT-BEADS-BETA-ONLY"
    )

    if (-not $IdA -or -not $IdB) {
        throw "Criação de tarefas falhou"
    }

    Invoke-BdProject $A @(
        "update", $IdA, "--status", "in_progress"
    ) | Out-Null

    Invoke-BdProject $B @(
        "update", $IdB, "--status", "in_progress"
    ) | Out-Null

    $ListA = Invoke-BdProject $A @("list", "--json")
    $ListB = Invoke-BdProject $B @("list", "--json")

    if (
        $ListA -notmatch "AUDIT-BEADS-ALPHA-ONLY" -or
        $ListA -match "AUDIT-BEADS-BETA-ONLY" -or
        $ListB -notmatch "AUDIT-BEADS-BETA-ONLY" -or
        $ListB -match "AUDIT-BEADS-ALPHA-ONLY"
    ) {
        throw "Falha de isolamento entre projetos"
    }

    foreach ($Project in @($A, $B)) {
        $Status = & git -C $Project status --porcelain

        if ($Status) {
            throw "Git sujo após mutações Beads: $Status"
        }
    }

    Write-Host "✅ Beads Windows security smoke passou"
}
finally {
    if ($null -eq $OldCI) {
        Remove-Item Env:CI -ErrorAction SilentlyContinue
    }
    else {
        $env:CI = $OldCI
    }

    if ($null -eq $OldMetrics) {
        Remove-Item Env:BD_DISABLE_METRICS `
            -ErrorAction SilentlyContinue
    }
    else {
        $env:BD_DISABLE_METRICS = $OldMetrics
    }

    if (Test-Path $Tmp) {
        for ($Attempt = 1; $Attempt -le 5; $Attempt++) {
            try {
                Remove-Item $Tmp -Recurse -Force -ErrorAction Stop
                break
            }
            catch {
                if ($Attempt -eq 5) {
                    Write-Warning "Não foi possível limpar: $Tmp"
                }
                else {
                    Start-Sleep -Milliseconds 500
                }
            }
        }
    }
}
