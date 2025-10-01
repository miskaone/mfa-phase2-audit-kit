
<# 
.SYNOPSIS
  Identify non-interactive ARM write operations likely to break under MFA Phase 2

.DESCRIPTION
  Placeholder skeleton for Audit-ARM-WriteSignIns. Implements consistent logging, Graph connection, and CSV output.

.REQUIRED SCOPES
  AuditLog.Read.All

.OUTPUT
  ARM_SignIns_NonInteractive.csv

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
Connect-GraphIfNeeded -Scopes @("AuditLog.Read.All")

# 2) Resolve output path
$out = New-OutputPath -Root $OutputRoot -Prefix "output"
$csv = Join-Path $out "ARM_SignIns_NonInteractive.csv"

# 3) Key functions (stubs)

function Query-ArmWriteSignIns {
    param([int]$DaysBack)
    # TODO: Query signIns logs (Workload=AzureResourceManager, isInteractive=false, operations=write)
    return @()
}
function Assess-Phase2Impact {
    param([Object[]]$Events)
    # TODO: mark WillBreakUnderPhase2
    return $Events
}
function Invoke-TargetQuery {
    param([int]$DaysBack)
    $events = Query-ArmWriteSignIns -DaysBack $DaysBack
    $assessed = Assess-Phase2Impact -Events $events
    return $assessed
}


# 4) Execute
Write-Log INFO "Running Audit-ARM-WriteSignIns ..."

try {
    $rows = Invoke-TargetQuery -DaysBack $DaysBack
    Export-Table -Data $rows -Path $csv
} catch {
    Write-Log ERROR $_.Exception.Message
    throw
}

Write-Log INFO "Audit-ARM-WriteSignIns completed."
