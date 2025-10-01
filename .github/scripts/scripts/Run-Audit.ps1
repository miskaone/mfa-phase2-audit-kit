
<# 
.SYNOPSIS
  Orchestrates running selected audit modules and writing outputs.
#>
[CmdletBinding()]
param(
  [Parameter()][string]$OutputRoot = ".\output",
  [switch]$IncludeGitHub,
  [string]$GitHubOrg,
  [switch]$IncludeAzDO
)

Import-Module "$PSScriptRoot/../scripts/Common.psm1" -Force

$ErrorActionPreference = "Stop"
$out = New-OutputPath -Root $OutputRoot -Prefix "output"
Write-Log INFO "Output root: $out"

# Core
& "$PSScriptRoot/../src/core/02_Audit-PrivilegedUsers.ps1" -OutputRoot $OutputRoot
& "$PSScriptRoot/../src/core/04_Audit-ConditionalAccess.ps1" -OutputRoot $OutputRoot
& "$PSScriptRoot/../src/core/08_Generate-Recommendations.ps1" -OutputRoot $OutputRoot

# Optional Phase 2
& "$PSScriptRoot/../src/core/03_Audit-ServicePrincipals.ps1" -OutputRoot $OutputRoot
& "$PSScriptRoot/../src/core/05_Audit-AdminAuthMethods.ps1" -OutputRoot $OutputRoot
& "$PSScriptRoot/../src/core/06_Audit-ARM-WriteSignIns.ps1" -OutputRoot $OutputRoot

# Phase 3
& "$PSScriptRoot/../src/core/07_Audit-MI-CapableResources.ps1" -OutputRoot $OutputRoot

# Phase 4 CI/CD
if ($IncludeGitHub) {
  & "$PSScriptRoot/../src/ci_cd/09_Audit-GitHubActions.ps1" -OutputRoot $OutputRoot
}
if ($IncludeAzDO) {
  & "$PSScriptRoot/../src/ci_cd/10_Audit-AzureDevOps.ps1" -OutputRoot $OutputRoot
}
& "$PSScriptRoot/../src/ci_cd/11_Generate-Extended-Recommendations.ps1" -OutputRoot $OutputRoot

Write-Log INFO "Run-Audit complete."
