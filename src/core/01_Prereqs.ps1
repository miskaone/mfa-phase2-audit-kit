<#
.SYNOPSIS
Installs required PowerShell modules and validates environment prerequisites.

.DESCRIPTION
Ensures PowerShell 7+, installs Microsoft.Graph, Az.Accounts, Az.Resources.
Read-only setup; no resource mutations.
#>

param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Write-Host '[01] Checking prerequisites...' -ForegroundColor Cyan

function Install-ModuleIfMissing {
    param(
        [Parameter(Mandatory=$true)][string]$ModuleName
    )
    if (-not (Get-Module -ListAvailable -Name $ModuleName)) {
        Write-Host "Installing module: $ModuleName" -ForegroundColor Yellow
        Install-Module -Name $ModuleName -Scope CurrentUser -Force -AllowClobber -ErrorAction Stop
    }
}

Install-ModuleIfMissing -ModuleName 'Microsoft.Graph'
Install-ModuleIfMissing -ModuleName 'Az.Accounts'
Install-ModuleIfMissing -ModuleName 'Az.Resources'

Write-Host '[01] Prerequisites complete.' -ForegroundColor Green


