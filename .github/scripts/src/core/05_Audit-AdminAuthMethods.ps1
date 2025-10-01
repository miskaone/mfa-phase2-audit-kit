
<# 
.SYNOPSIS
  Summarize admin authentication methods (FIDO2, passkey, authenticator)

.DESCRIPTION
  Placeholder skeleton for Audit-AdminAuthMethods. Implements consistent logging, Graph connection, and CSV output.

.REQUIRED SCOPES
  UserAuthenticationMethod.Read.All, Directory.Read.All

.OUTPUT
  Admin_AuthMethods.csv

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
Connect-GraphIfNeeded -Scopes @("UserAuthenticationMethod.Read.All", "Directory.Read.All")

# 2) Resolve output path
$out = New-OutputPath -Root $OutputRoot -Prefix "output"
$csv = Join-Path $out "Admin_AuthMethods.csv"

# 3) Key functions (stubs)

function Get-AdminUsers {
    # TODO: derive from role mapping or filter by role
    return @()
}
function Get-UserAuthSummary {
    param($Upn)
    # TODO: Get-MgUserAuthenticationMethod -UserId $Upn; summarize into booleans
    return [PSCustomObject]@{{ UserPrincipalName=$Upn; FIDO2=$false; Passkey=$false; AuthenticatorApp=$false; Phone=$false; PasswordlessEnabled=$false }}
}
function Invoke-TargetQuery {
    param([int]$DaysBack)
    $admins = Get-AdminUsers
    $rows = foreach ($a in $admins) { Get-UserAuthSummary -Upn $a.UserPrincipalName }
    return $rows
}


# 4) Execute
Write-Log INFO "Running Audit-AdminAuthMethods ..."

try {
    $rows = Invoke-TargetQuery -DaysBack $DaysBack
    Export-Table -Data $rows -Path $csv
} catch {
    Write-Log ERROR $_.Exception.Message
    throw
}

Write-Log INFO "Audit-AdminAuthMethods completed."
