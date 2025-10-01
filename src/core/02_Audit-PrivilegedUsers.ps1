# src/core/02_Audit-PrivilegedUsers.ps1

. "$PSScriptRoot/../common/Graph.Bootstrap.ps1"
Connect-GraphAudience

function Get-DirectoryRoles {
    Invoke-GraphWithRetry { Get-MgRoleManagementDirectoryRoleDefinition -All -Property Id,DisplayName }
}

function Get-RoleAssignmentsByRoleId {
    param([string]$RoleId)
    Invoke-GraphWithRetry {
        Get-MgRoleManagementDirectoryRoleAssignment -All -Filter "roleDefinitionId eq '$RoleId'" -Property Id,PrincipalId,PrincipalType,RoleDefinitionId
    }
}

function Get-UserShallow {
    param([string]$UserId)
    Invoke-GraphWithRetry {
        # Pull signInActivity if available in your SDK build
        Get-MgUser -UserId $UserId -Property "id,userPrincipalName,displayName,accountEnabled,signInActivity"
    }
}

function Get-UserAuthMethods {
    param([string]$UserId)
    Invoke-GraphWithRetry {
        Get-MgUserAuthenticationMethod -UserId $UserId -All
    }
}

function Classify-AuthSet {
    param([Object[]]$Methods)
    $types = @()
    foreach ($m in $Methods) {
        switch ($m.'@odata.type') {
            '#microsoft.graph.fido2AuthenticationMethod'                { $types += 'fido2' }
            '#microsoft.graph.microsoftAuthenticatorAuthenticationMethod' {
                # Some tenants expose passkeys via this type
                if ($m.PSObject.Properties.Name -contains 'IsPasskey' -and $m.IsPasskey) { $types += 'passkey' }
                else { $types += 'authenticator' }
            }
            '#microsoft.graph.passwordAuthenticationMethod'             { $types += 'password' }
            '#microsoft.graph.phoneAuthenticationMethod'                { $types += 'phone' }
            default                                                     { $types += 'other' }
        }
    }
    $strong = @('fido2','passkey','authenticator')
    [PSCustomObject]@{
        Methods       = $types
        HasStrong     = ($types | Where-Object { $_ -in $strong }).Count -gt 0
        PrimaryMethod = if ($types -contains 'fido2') {'FIDO2'}
                        elseif ($types -contains 'passkey') {'Passkey'}
                        elseif ($types -contains 'authenticator') {'Authenticator App'}
                        elseif ($types -contains 'phone') {'Phone'}
                        elseif ($types -contains 'password') {'Password'}
                        else {'Unknown'}
    }
}

function Test-BreakGlassAccount {
    param(
        [Parameter(Mandatory)] $UserRow
    )
    $indicators = @()

    if ($UserRow.IsPrivileged -and -not $UserRow.MFA_Enabled) {
        $indicators += "High privilege without MFA"
    }
    if ($UserRow.AuthMethods -eq @('password')) {
        $indicators += "Password-only authentication"
    }
    if ($UserRow.LastSignIn -and $UserRow.LastSignIn -lt (Get-Date).AddDays(-30)) {
        $indicators += "No recent sign-ins (>30d)"
    }
    # CA exclusion enrichment can be appended by 04_… script join

    [PSCustomObject]@{
        IsBreakGlass = $indicators.Count -gt 0
        Indicators   = $indicators
        RiskScore    = [Math]::Min(100, $indicators.Count * 25)
    }
}

function Get-PrivilegedUsers {
    Write-Progress -Activity "Privileged Users" -Status "Roles" -PercentComplete 10
    $roles = Get-DirectoryRoles

    $rows = New-Object System.Collections.Generic.List[object]
    $rIx  = 0
    foreach ($role in $roles) {
        $rIx++
        Write-Progress -Activity "Privileged Users" -Status "Assignments for $($role.DisplayName)" -PercentComplete ([int](10 + (80*($rIx/$($roles.Count)))))

        $assignments = Get-RoleAssignmentsByRoleId -RoleId $role.Id
        foreach ($a in $assignments) {
            if ($a.PrincipalType -ne 'User') { continue }

            $u = Get-UserShallow -UserId $a.PrincipalId
            if (-not $u) { continue }

            $auth = Get-UserAuthMethods -UserId $u.Id
            $cls  = Classify-AuthSet -Methods $auth

            $mfaEnabled = $cls.HasStrong
            $lastSignIn = $null
            if ($u.PSObject.Properties.Name -contains 'SignInActivity' -and $u.SignInActivity) {
                $lastSignIn = $u.SignInActivity.LastSignInDateTime
            }

            $row = [PSCustomObject]@{
                RoleId               = $role.Id
                RoleName             = $role.DisplayName
                UserId               = $u.Id
                UserPrincipalName    = $u.UserPrincipalName
                DisplayName          = $u.DisplayName
                IsPrivileged         = $true
                MFA_Enabled          = $mfaEnabled
                LastSignIn           = $lastSignIn
                AuthMethods          = $cls.Methods
                PrimaryAuthMethod    = $cls.PrimaryMethod
                ExcludedFromCA       = $false   # join later from CA audit
                ExceptionsPolicyName = $null
            }

            $bg = Test-BreakGlassAccount -UserRow $row
            $rows.Add(($row | Select-Object *,
                @{n='IsBreakGlass';e={$bg.IsBreakGlass}},
                @{n='BreakGlassIndicators';e={$bg.Indicators -join '; '}},
                @{n='RiskLevel';e={
                    switch ($bg.RiskScore) { {$_ -ge 75} {'Critical'} {$_ -ge 50} {'High'} {$_ -ge 25} {'Medium'} default {'Low'} }
                }}
            ))
        }
        Start-Sleep -Milliseconds 50
    }

    Write-Progress -Activity "Privileged Users" -Completed
    $rows
}

# ENTRY
if ($MyInvocation.PSScriptRoot) {
    $data = Get-PrivilegedUsers
    $out  = Join-Path $PSScriptRoot '..\..\output\Admins_ByRole.csv'
    $data | Sort-Object RoleName,UserPrincipalName | Export-Csv -NoTypeInformation -Path $out -Encoding UTF8
    Write-Log INFO "Wrote $($data.Count) rows to $out"
}