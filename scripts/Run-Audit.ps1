<#
.SYNOPSIS
Orchestrates the full MFA Phase 2 audit.

.DESCRIPTION
Runs core and optional CI/CD modules, then generates recommendations.
#>

param(
    [string]$OutputRoot = (Join-Path (Get-Location) 'output'),
    [switch]$IncludeGitHub,
    [string]$GitHubOrg,
    [switch]$IncludeAzDO
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$timestamp = (Get-Date).ToString('yyyyMMdd_HHmmss')
$runRoot   = Join-Path $OutputRoot $timestamp
New-Item -ItemType Directory -Force -Path $runRoot | Out-Null

& (Join-Path $PSScriptRoot '..' 'src' 'core' '01_Prereqs.ps1')
& (Join-Path $PSScriptRoot '..' 'src' 'core' '02_Audit-PrivilegedUsers.ps1') -OutputPath $runRoot
& (Join-Path $PSScriptRoot '..' 'src' 'core' '03_Audit-ServicePrincipals.ps1') -OutputPath $runRoot
& (Join-Path $PSScriptRoot '..' 'src' 'core' '04_Audit-ConditionalAccess.ps1') -OutputPath $runRoot
& (Join-Path $PSScriptRoot '..' 'src' 'core' '05_Audit-AdminAuthMethods.ps1') -OutputPath $runRoot
& (Join-Path $PSScriptRoot '..' 'src' 'core' '06_Audit-ARM-WriteSignIns.ps1') -OutputPath $runRoot
& (Join-Path $PSScriptRoot '..' 'src' 'core' '07_Audit-MI-CapableResources.ps1') -OutputPath $runRoot

if ($IncludeGitHub) {
    & (Join-Path $PSScriptRoot '..' 'src' 'ci_cd' '09_Audit-GitHubActions.ps1') -GitHubOrg $GitHubOrg -OutputPath $runRoot
}
if ($IncludeAzDO) {
    & (Join-Path $PSScriptRoot '..' 'src' 'ci_cd' '10_Audit-AzureDevOps.ps1') -OutputPath $runRoot
}

& (Join-Path $PSScriptRoot '..' 'src' 'core' '08_Generate-Recommendations.ps1') -InputRoot $runRoot
& (Join-Path $PSScriptRoot '..' 'src' 'ci_cd' '11_Generate-Extended-Recommendations.ps1') -InputRoot $runRoot

Write-Host "Audit completed. Output: $runRoot" -ForegroundColor Green


