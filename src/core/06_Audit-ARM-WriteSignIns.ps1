# src/core/06_Audit-ARM-WriteSignIns.ps1
. "$PSScriptRoot/../common/Graph.Bootstrap.ps1"
Connect-GraphAudience -Scopes @('AuditLog.Read.All')

function Get-SignInsWindow {
    param(
        [datetime]$Start = (Get-Date).AddDays(-7),
        [datetime]$End   = (Get-Date)
    )
    # Use $filter for date window; select fields we need
    $filter = "createdDateTime ge $($Start.ToString('o')) and createdDateTime le $($End.ToString('o'))"
    Invoke-GraphWithRetry {
        Get-MgAuditLogSignIn -All -Filter $filter -Property "id,createdDateTime,userDisplayName,userPrincipalName,appDisplayName,ipAddress,clientAppUsed,isInteractive,conditionalAccessStatus,riskLevelAggregated"
    }
}

function Classify-ARMRiskRow {
    param($s)
    $risks = @()
    $impact = 'None'

    if (-not $s.IsInteractive -and $s.ConditionalAccessStatus -ne 'satisfied') {
        $risks += 'Non-interactive without satisfied CA'
        $impact = 'High - Likely to fail under stricter enforcement'
    }
    if ($s.ClientAppUsed -eq 'Other clients' -and $s.AppDisplayName -match 'ServicePrincipal') {
        $risks += 'Service principal using legacy flow'
        $impact = 'High - Migrate to Managed Identity'
    }

    [PSCustomObject]@{
        TenantId       = $null
        SubscriptionId = $null
        CorrelationId  = $s.Id
        Timestamp      = $s.CreatedDateTime
        UserPrincipalName = $s.UserPrincipalName
        IPAddress      = $s.IpAddress
        UserAgent      = $null
        ClientAppUsed  = $s.ClientAppUsed
        ResourceId     = $null
        Action         = $null
        OperationName  = $null
        PrincipalId    = $null
        AppId          = $null
        IsInteractive  = $s.IsInteractive
        IsServicePrincipal = ($s.UserPrincipalName -match '^[0-9a-f-]{36}@')
        MFA_Required   = $null
        MFA_Completed  = if ($s.ConditionalAccessStatus -eq 'satisfied') {$true} else {$false}
        RiskLevel      = if ($risks.Count -ge 2) {'High'} elseif ($risks.Count -eq 1) {'Medium'} else {'Low'}
        Phase2Impact   = $impact
    }
}

function Get-ARMSignInFindings {
    $signins = Get-SignInsWindow
    foreach ($s in $signins) { Classify-ARMRiskRow -s $s }
}

# ENTRY
if ($MyInvocation.PSScriptRoot) {
    $data = Get-ARMSignInFindings
    $out  = Join-Path $PSScriptRoot '..\..\output\ARM_SignIns.csv'
    $data | Export-Csv -NoTypeInformation -Path $out -Encoding UTF8
    Write-Log INFO "Wrote $($data.Count) sign-in rows to $out"
}