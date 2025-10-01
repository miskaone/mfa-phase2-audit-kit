
Set-StrictMode -Version Latest

function New-OutputPath {
    param(
        [Parameter(Mandatory=$true)][string]$Root,
        [string]$Prefix = "output"
    )
    $ts = Get-Date -Format "yyyyMMdd-HHmmss"
    $path = Join-Path -Path $Root -ChildPath "$Prefix/$ts"
    if (-not (Test-Path $path)) { New-Item -ItemType Directory -Force -Path $path | Out-Null }
    return $path
}

function Write-Log {
    param(
        [Parameter(Mandatory=$true)][ValidateSet('INFO','WARN','ERROR','DEBUG')] [string]$Level,
        [Parameter(Mandatory=$true)] [string]$Message
    )
    $ts = Get-Date -Format "s"
    Write-Host "[$ts][$Level] $Message"
}

function Export-Table {
    param(
        [Parameter(Mandatory=$true)] [Object[]]$Data,
        [Parameter(Mandatory=$true)] [string]$Path
    )
    if ($null -eq $Data -or $Data.Count -eq 0) {
        Write-Log WARN "No rows to export for $Path"
        "" | Out-File -FilePath $Path -Encoding utf8
        return
    }
    $Data | Export-Csv -Path $Path -NoTypeInformation -Encoding UTF8
    Write-Log INFO "Wrote $(($Data | Measure-Object).Count) rows -> $Path"
}

function Ensure-Modules {
    param(
        [string[]]$Names = @("Microsoft.Graph","Az.Accounts","Az.Resources")
    )
    foreach ($n in $Names) {
        if (-not (Get-Module -ListAvailable -Name $n)) {
            Write-Log INFO "Installing module: $n"
            Install-Module -Name $n -Scope CurrentUser -Force -AllowClobber -ErrorAction Stop
        }
        Import-Module $n -ErrorAction Stop
    }
}

function Connect-GraphIfNeeded {
    param(
        [string[]]$Scopes
    )
    try {
        if (-not (Get-MgContext)) {
            Write-Log INFO "Connecting to Microsoft Graph with scopes: $($Scopes -join ',')"
            Connect-MgGraph -Scopes $Scopes -NoWelcome
        }
    } catch {
        throw "Failed to connect to Graph: $($_.Exception.Message)"
    }
}
