# src/core/04_Audit-ConditionalAccess.ps1
. "$PSScriptRoot/../common/Graph.Bootstrap.ps1"
Connect-GraphAudience -Scopes @('Policy.Read.All','Directory.Read.All')

function Get-ConditionalAccessPolicies {
    Invoke-GraphWithRetry {
        # Mg cmdlet already pages with -All
        Get-MgIdentityConditionalAccessPolicy -All
    }
}

function Analyze-Policy {
    param($p)

    $grantControls = @()
    $requiresMfa   = $false
    if ($p.GrantControls) {
        # In SDK v2+, use properties GrantControls.BuiltInControls
        if ($p.GrantControls.GrantControlTypes) { $grantControls = $p.GrantControls.GrantControlTypes }
        if ($p.GrantControls.BuiltInControls)   { $grantControls = $p.GrantControls.BuiltInControls }
        $requiresMfa = $grantControls -contains 'mfa' -or $grantControls -contains 'requireMultiFactorAuthentication'
    }

    $excludedUsers  = @()
    $excludedGroups = @()
    if ($p.Conditions -and $p.Conditions.Users) {
        if ($p.Conditions.Users.ExcludeUsers)  { $excludedUsers  = $p.Conditions.Users.ExcludeUsers }
        if ($p.Conditions.Users.ExcludeGroups) { $excludedGroups = $p.Conditions.Users.ExcludeGroups }
    }
    $hasRiskyExclusions = $requiresMfa -and ( ($excludedUsers.Count + $excludedGroups.Count) -gt 0 )

    # Light summarization—expand as needed
    [PSCustomObject]@{
        PolicyId             = $p.Id
        DisplayName          = $p.DisplayName
        State                = $p.State
        AppliesTo            = if ($p.Conditions.Users.IncludeUsers -contains 'All') {'All users'} else {'Scoped'}
        ClientApps           = if ($p.Conditions.ClientAppTypes) { ($p.Conditions.ClientAppTypes -join ',') } else {'All'}
        SignInRisk           = if ($p.Conditions.SignInRiskLevels){ ($p.Conditions.SignInRiskLevels -join ',') } else {'None'}
        SessionControls      = if ($p.SessionControls) {'Configured'} else {'None'}
        EffectiveMFAEnforced = $requiresMfa
        HasRiskyExclusions   = $hasRiskyExclusions
        ExcludedUsers        = $excludedUsers
        ExcludedGroups       = $excludedGroups
        RiskLevel            = if ($p.State -eq 'disabled') {'High'}
                               elseif (-not $requiresMfa) {'Medium'}
                               elseif ($hasRiskyExclusions) {'Medium'}
                               else {'Low'}
        Recommendations      = @( if ($p.State -eq 'disabled') {'Enable or remove if obsolete'}
                                  if (-not $requiresMfa) {'Add MFA to grant controls'}
                                  if ($hasRiskyExclusions) {'Review and minimize exclusions'}
                                )
    }
}

function Get-ConditionalAccessPoliciesAnalyzed {
    $pols = Get-ConditionalAccessPolicies
    $out  = foreach ($p in $pols) { Analyze-Policy -p $p }
    $out
}

# Optional join back to privileged users CSV to mark CA exclusions
function Join-CAFindingsIntoPrivilegedUsers {
    param(
        [string]$PrivilegedUsersCsv
    )
    if (-not (Test-Path $PrivilegedUsersCsv)) { return }
    $users = Import-Csv $PrivilegedUsersCsv
    $pols  = Get-ConditionalAccessPolicies

    # naively mark exclusions by UPN if listed explicitly in policy
    $excludedUpns = @()
    foreach ($p in $pols) {
        $ex = $p.Conditions.Users.ExcludeUsers
        if ($ex) { $excludedUpns += $ex }
    }
    $excludedUpns = $excludedUpns | Sort-Object -Unique

    foreach ($u in $users) {
        if ($excludedUpns -contains $u.UserPrincipalName) {
            $u.ExcludedFromCA = $true
            $u.ExceptionsPolicyName = 'One or more CA policies'
        }
    }
    $users | Export-Csv -NoTypeInformation -Path $PrivilegedUsersCsv -Encoding UTF8
}

# ENTRY
if ($MyInvocation.PSScriptRoot) {
    $data = Get-ConditionalAccessPoliciesAnalyzed
    $out  = Join-Path $PSScriptRoot '..\..\output\CA_Policies.csv'
    $data | Export-Csv -NoTypeInformation -Path $out -Encoding UTF8
    Write-Log INFO "Wrote $($data.Count) CA policies to $out"
}