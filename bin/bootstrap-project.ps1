$ErrorActionPreference = "Stop"

$Script = Join-Path $PSScriptRoot "windows\bootstrap-project.ps1"

if (-not (Test-Path $Script)) {
    throw "bootstrap-project Windows ausente: $Script"
}

$ProjectPath = "."
$Positionals = @()

$Options = @{
    Beads = $false
    OpenSpec = $false
    Standard = $false
    DbHub = $false
}

foreach ($Arg in @($args)) {
    if ($Arg -eq "--beads" -or $Arg -eq "-Beads") {
        $Options["Beads"] = $true
    }
    elseif ($Arg -eq "--openspec" -or $Arg -eq "-OpenSpec") {
        $Options["OpenSpec"] = $true
    }
    elseif ($Arg -eq "--standard" -or $Arg -eq "-Standard") {
        $Options["Standard"] = $true
    }
    elseif ($Arg -eq "--dbhub" -or $Arg -eq "-DbHub") {
        $Options["DbHub"] = $true
    }
    elseif ($Arg -is [string] -and $Arg.StartsWith("-")) {
        throw "Opção desconhecida: $Arg"
    }
    else {
        $Positionals += $Arg
    }
}

if ($Positionals.Count -gt 1) {
    throw "Apenas um caminho de projeto pode ser informado."
}

if ($Positionals.Count -eq 1) {
    $ProjectPath = $Positionals[0]
}

$Invoke = @{
    Path = $ProjectPath
}

foreach ($Name in $Options.Keys) {
    if ($Options[$Name]) {
        $Invoke[$Name] = $true
    }
}

& $Script @Invoke
exit $LASTEXITCODE
