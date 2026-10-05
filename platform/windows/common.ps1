$ErrorActionPreference = "Stop"

$script:Kit = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)

$script:LocalRoot = Join-Path $HOME ".local"
$script:BinRoot   = Join-Path $LocalRoot "bin"
$script:OptRoot   = Join-Path $LocalRoot "opt"
$script:ShareRoot = Join-Path $LocalRoot "share"

$script:ProfilesRoot = Join-Path $HOME ".codex-profiles"
$script:SharedSkills = Join-Path $HOME ".codex-shared\skills"
$script:McporterHome = Join-Path $HOME ".mcporter"

function Write-Step {
    param([string]$Message)
    Write-Host ""
    Write-Host "==> $Message"
}

function Write-Ok {
    param([string]$Message)
    Write-Host "    OK: $Message"
}

function Ensure-Directory {
    param([string]$Path)

    if (-not (Test-Path $Path)) {
        New-Item -ItemType Directory -Force -Path $Path | Out-Null
    }
}

function Read-EnvManifest {
    param([string]$Path)

    $Result = @{}

    Get-Content $Path | ForEach-Object {
        $Line = $_.Trim()

        if (-not $Line -or $Line.StartsWith("#")) {
            return
        }

        if ($Line -match '^([A-Z0-9_]+)=(.*)$') {
            $Name = $Matches[1]
            $Value = $Matches[2].Trim()

            if ($Value -match '^"(.*?)"(?:\s+#.*)?$') {
                $Value = $Matches[1]
            }
            elseif ($Value -match "^'(.*?)'(?:\s+#.*)?$") {
                $Value = $Matches[1]
            }
            else {
                $Value = ($Value -replace '\s+#.*$', '').Trim()
            }

            $Result[$Name] = $Value
        }
    }

    return $Result
}
