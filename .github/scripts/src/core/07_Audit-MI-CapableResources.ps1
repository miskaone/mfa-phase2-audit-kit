
<# 
.SYNOPSIS
  List MI-capable resources and whether identity is configured

.DESCRIPTION
  Placeholder skeleton for Audit-MI-CapableResources. Implements consistent logging, Graph connection, and CSV output.

.REQUIRED SCOPES
  Directory.Read.All

.OUTPUT
  ManagedIdentity_Capable_Resources.csv

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
$csv = Join-Path $out "ManagedIdentity_Capable_Resources.csv"

# 3) Key functions (stubs)

function Get-MIResources {
    # TODO: Use Az.Resources to enumerate resource types and identity blocks
    return @()
}
function Invoke-TargetQuery {
    param([int]$DaysBack)
    $rows = Get-MIResources
    return $rows
}


# 4) Execute
Write-Log INFO "Running Audit-MI-CapableResources ..."

try {
    $rows = Invoke-TargetQuery -DaysBack $DaysBack
    Export-Table -Data $rows -Path $csv
} catch {
    Write-Log ERROR $_.Exception.Message
    throw
}

Write-Log INFO "Audit-MI-CapableResources completed."
