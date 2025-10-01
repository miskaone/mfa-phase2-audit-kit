
<# 
.SYNOPSIS
  Inventory service principals and credential posture (password/cert/federated)

.DESCRIPTION
  Placeholder skeleton for Audit-ServicePrincipals. Implements consistent logging, Graph connection, and CSV output.

.REQUIRED SCOPES
  Directory.Read.All

.OUTPUT
  ServicePrincipals_Credentials.csv

.DEPENDENCIES
  Microsoft.Graph, Az.Accounts, Az.Resources

.ENVIRONMENT
  None

#>

[CmdletBinding()]
param(
  [Parameter()][string]$OutputRoot = ".\output",
  [Parameter()][int]$DaysBack = 14
)

Import-Module "/mnt/data/scripts/Common.psm1" -Force
Set-StrictMode -Version Latest

$ErrorActionPreference = "Stop"

# 1) Ensure modules & connect Graph
Ensure-Modules -Names @("Microsoft.Graph", "Az.Accounts", "Az.Resources")
Connect-GraphIfNeeded -Scopes @("Directory.Read.All")

# 2) Resolve output path
$out = New-OutputPath -Root $OutputRoot -Prefix "output"
$csv = Join-Path $out "ServicePrincipals_Credentials.csv"

# 3) Key functions (stubs)

function Get-ServicePrincipals {
    # TODO: Get-MgServicePrincipal -All -Property * | select AppId, DisplayName, PasswordCredentials, KeyCredentials
    return @()
}
function Classify-Credential {
    param($Sp)
    # TODO: Return CredentialType + Expiry + Status
    return [PSCustomObject]@{ AppId=$Sp.AppId; DisplayName=$Sp.DisplayName; CredentialType="Password"; ExpiryDate=$null; Status="Unknown" }
}
function Invoke-TargetQuery {
    param([int]$DaysBack)
    $sps = Get-ServicePrincipals
    $rows = foreach ($sp in $sps) { Classify-Credential -Sp $sp }
    return $rows
}


# 4) Execute
Write-Log INFO "Running Audit-ServicePrincipals ..."

try {
    $rows = Invoke-TargetQuery -DaysBack $DaysBack
    Export-Table -Data $rows -Path $csv
} catch {
    Write-Log ERROR $_.Exception.Message
    throw
}

Write-Log INFO "Audit-ServicePrincipals completed."
