# src/core/03_Audit-ServicePrincipals.ps1
. "$PSScriptRoot/../common/Graph.Bootstrap.ps1"
Connect-GraphAudience -Scopes @('Application.Read.All','Directory.Read.All')

function Get-ServicePrincipalsBasic {
    Invoke-GraphWithRetry {
        Get-MgServicePrincipal -All -Property "id,appId,displayName,appOwnerOrganizationId,appRoles"
    }
}

function Get-SPCredentials {
    param([string]$SpId)
    # Certificates & secrets are exposed via /servicePrincipals/{id} endpoints:
    $keys = Invoke-GraphWithRetry { Get-MgServicePrincipalKey -ServicePrincipalId $SpId -ErrorAction Stop }
    # Above returns passwordCredentials and keyCredentials in most SDK builds
    $keys
}

function Get-SPOAuthGrants {
    param([string]$SpId)
    Invoke-GraphWithRetry { Get-MgServicePrincipalOauth2PermissionGrant -ServicePrincipalId $SpId -All }
}

function Score-SP {
    param($sp, $keys, $grants)

    $secrets = @($keys.passwordCredentials) | Where-Object { $_ }
    $certs   = @($keys.keyCredentials)      | Where-Object { $_ }

    $risks = @()
    if ($secrets | Where-Object { $_.EndDateTime -lt (Get-Date) }) { $risks += 'Expired client secrets' }
    if ($secrets | Where-Object { $_.EndDateTime -gt (Get-Date).AddYears(1) }) { $risks += 'Long-lived client secrets' }
    if (-not $certs) { $risks += 'No certificate authentication' }

    $riskLevel = switch ($risks.Count) { 0 {'Low'} 1..2 {'Medium'} 3..4 {'High'} default {'Critical'} }

    [PSCustomObject]@{
        AppId              = $sp.AppId
        DisplayName        = $sp.DisplayName
        AppType            = 'ServicePrincipal'
        IsPrivileged       = [bool]($sp.AppRoles | Where-Object { $_.Value -match 'Admin' })
        HasClientSecret    = $secrets.Count -gt 0
        HasCertificate     = $certs.Count -gt 0
        SecretExpiry       = ($secrets | Sort-Object EndDateTime | Select-Object -Last 1).EndDateTime
        CertificateExpiry  = ($certs   | Sort-Object EndDateTime | Select-Object -Last 1).EndDateTime
        OAuthGrants        = @($grants.scope) | Sort-Object -Unique
        RiskLevel          = $riskLevel
        MigrationTarget    = if ($certs.Count -eq 0) {'ManagedIdentity'} else {'ServicePrincipal'}
        LastUsed           = $null # populate later from sign-ins if needed
    }
}

function Get-ServicePrincipalsAudit {
    $sps = Get-ServicePrincipalsBasic
    foreach ($sp in $sps) {
        $keys   = Get-SPCredentials -SpId $sp.Id
        $grants = Get-SPOAuthGrants  -SpId $sp.Id
        Score-SP -sp $sp -keys $keys -grants $grants
        Start-Sleep -Milliseconds 40
    }
}

# ENTRY
if ($MyInvocation.PSScriptRoot) {
    $data = Get-ServicePrincipalsAudit
    $out  = Join-Path $PSScriptRoot '..\..\output\ServicePrincipals.csv'
    $data | Export-Csv -NoTypeInformation -Path $out -Encoding UTF8
    Write-Log INFO "Wrote $($data.Count) SP rows to $out"
}