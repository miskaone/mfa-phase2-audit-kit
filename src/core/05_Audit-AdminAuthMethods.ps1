# src/core/05_Audit-AdminAuthMethods.ps1
. "$PSScriptRoot/../common/Graph.Bootstrap.ps1"
Connect-GraphAudience -Scopes @('User.Read.All','Directory.Read.All')

function Get-PrivilegedUserIdsFromCsv {
    param([string]$Path)
    (Import-Csv $Path | Where-Object { $_.IsPrivileged -eq 'True' }).UserId | Sort-Object -Unique
}

function Get-UserAuthSummaryRow {
    param([string]$UserId)

    $u = Invoke-GraphWithRetry { Get-MgUser -UserId $UserId -Property "id,userPrincipalName,displayName" }
    $m = Invoke-GraphWithRetry { Get-MgUserAuthenticationMethod -UserId $UserId -All }
    $types = foreach ($mm in $m) { $mm.'@odata.type' }
    $hasFido     = $types -contains '#microsoft.graph.fido2AuthenticationMethod'
    $hasPasskey  = ($m | Where-Object { $_.PSObject.Properties.Name -contains 'IsPasskey' -and $_.IsPasskey }).Count -gt 0
    $hasAuthApp  = $types -contains '#microsoft.graph.microsoftAuthenticatorAuthenticationMethod'
    $hasPhone    = $types -contains '#microsoft.graph.phoneAuthenticationMethod'
    $hasPwdOnly  = $types -contains '#microsoft.graph.passwordAuthenticationMethod' -and -not ($hasFido -or $hasPasskey -or $hasAuthApp -or $hasPhone)

    $authList = @()
    if ($hasFido)    { $authList += 'fido2' }
    if ($hasPasskey) { $authList += 'passkey' }
    if ($hasAuthApp) { $authList += 'authenticator' }
    if ($hasPhone)   { $authList += 'phone' }
    if ($types -contains '#microsoft.graph.passwordAuthenticationMethod'){ $authList += 'password' }

    $strong = @('fido2','passkey','authenticator')
    $risks  = @()
    $recs   = @()

    if (-not ($authList | Where-Object { $_ -in $strong })) {
        $risks += "No strong authentication"
        $recs  += "Enable FIDO2 or passkeys"
    }
    if ($hasPwdOnly) {
        $risks += "Password-only authentication"
        $recs  += "Add Authenticator + FIDO2/passkeys"
    }

    [PSCustomObject]@{
        UserId            = $u.Id
        UserPrincipalName = $u.UserPrincipalName
        DisplayName       = $u.DisplayName
        IsPrivileged      = $true
        MFA_Enabled       = [bool]($authList | Where-Object { $_ -in $strong })
        AuthMethods       = $authList
        FIDO2_Enabled     = $hasFido
        Phone_Enabled     = $hasPhone
        Password_Enabled  = ($authList -contains 'password')
        StrongAuthCount   = ($authList | Where-Object { $_ -in $strong }).Count
        WeakAuthCount     = ($authList | Where-Object { $_ -in @('password','phone') }).Count
        RiskLevel         = if ($risks.Count -ge 2) {'High'} elseif ($risks.Count -eq 1) {'Medium'} else {'Low'}
        Recommendations   = $recs
    }
}

function Get-AdminAuthMethods {
    param([string]$PrivilegedUsersCsv)
    $ids = Get-PrivilegedUserIdsFromCsv -Path $PrivilegedUsersCsv
    $rows = foreach ($id in $ids) { Get-UserAuthSummaryRow -UserId $id }
    $rows
}

# ENTRY
if ($MyInvocation.PSScriptRoot) {
    $puCsv = Join-Path $PSScriptRoot '..\..\output\Admins_ByRole.csv'
    $data  = Get-AdminAuthMethods -PrivilegedUsersCsv $puCsv
    $out   = Join-Path $PSScriptRoot '..\..\output\Admins_AuthMethods.csv'
    $data | Export-Csv -NoTypeInformation -Path $out -Encoding UTF8
    Write-Log INFO "Wrote $($data.Count) admin auth rows to $out"
}