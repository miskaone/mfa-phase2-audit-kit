<#
.SYNOPSIS
Installs required PowerShell modules and validates environment prerequisites.

.DESCRIPTION
Ensures PowerShell 7+, installs Microsoft.Graph, Az.Accounts, Az.Resources.
Read-only setup; no resource mutations.

.DEPENDENCIES
Common.psm1

.ENVIRONMENT
None
#>

[CmdletBinding()]
param()

Import-Module "$PSScriptRoot\..\..\scripts\Common.psm1" -Force
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Write-Log INFO "Checking prerequisites..."

# Ensure required modules are installed and imported
Ensure-Modules -Names @("Microsoft.Graph", "Az.Accounts", "Az.Resources")

Write-Log INFO "Prerequisites complete."


