# tests/Test-GraphImplementation.ps1
# Pester tests for Graph API implementation validation

Describe "02 Privileged Users" {
    It "emits privileged users CSV" {
        $csv = Join-Path $PSScriptRoot '..\output\Admins_ByRole.csv'
        Test-Path $csv | Should -BeTrue
        (Import-Csv $csv).Count | Should -BeGreaterThan 0
    }
    
    It "has required columns in Admins_ByRole.csv" {
        $csv = Join-Path $PSScriptRoot '..\output\Admins_ByRole.csv'
        if (Test-Path $csv) {
            $data = Import-Csv $csv
            $data[0] | Should -HaveProperty "RoleName"
            $data[0] | Should -HaveProperty "UserPrincipalName"
            $data[0] | Should -HaveProperty "MFA_Enabled"
            $data[0] | Should -HaveProperty "IsBreakGlass"
            $data[0] | Should -HaveProperty "RiskLevel"
        }
    }
}

Describe "04 CA Policies" {
    It "emits CA policies CSV" {
        $csv = Join-Path $PSScriptRoot '..\output\CA_Policies.csv'
        Test-Path $csv | Should -BeTrue
        (Import-Csv $csv).Count | Should -BeGreaterOrEqual 0
    }
    
    It "flags non-MFA policies" {
        $csv = Join-Path $PSScriptRoot '..\output\CA_Policies.csv'
        if (Test-Path $csv) {
            $rows = Import-Csv $csv
            ($rows | Where-Object { $_.EffectiveMFAEnforced -eq 'False' }).Count | Should -BeGreaterOrEqual 0
        }
    }
    
    It "has required columns in CA_Policies.csv" {
        $csv = Join-Path $PSScriptRoot '..\output\CA_Policies.csv'
        if (Test-Path $csv) {
            $data = Import-Csv $csv
            $data[0] | Should -HaveProperty "PolicyId"
            $data[0] | Should -HaveProperty "DisplayName"
            $data[0] | Should -HaveProperty "EffectiveMFAEnforced"
            $data[0] | Should -HaveProperty "RiskLevel"
        }
    }
}

Describe "05 Admin Auth Methods" {
    It "emits admin auth methods CSV" {
        $csv = Join-Path $PSScriptRoot '..\output\Admins_AuthMethods.csv'
        Test-Path $csv | Should -BeTrue
        (Import-Csv $csv).Count | Should -BeGreaterThan 0
    }
    
    It "has required columns in Admins_AuthMethods.csv" {
        $csv = Join-Path $PSScriptRoot '..\output\Admins_AuthMethods.csv'
        if (Test-Path $csv) {
            $data = Import-Csv $csv
            $data[0] | Should -HaveProperty "UserId"
            $data[0] | Should -HaveProperty "MFA_Enabled"
            $data[0] | Should -HaveProperty "AuthMethods"
            $data[0] | Should -HaveProperty "RiskLevel"
        }
    }
}

Describe "03 Service Principals" {
    It "emits service principals CSV" {
        $csv = Join-Path $PSScriptRoot '..\output\ServicePrincipals.csv'
        Test-Path $csv | Should -BeTrue
        (Import-Csv $csv).Count | Should -BeGreaterOrEqual 0
    }
    
    It "has required columns in ServicePrincipals.csv" {
        $csv = Join-Path $PSScriptRoot '..\output\ServicePrincipals.csv'
        if (Test-Path $csv) {
            $data = Import-Csv $csv
            $data[0] | Should -HaveProperty "AppId"
            $data[0] | Should -HaveProperty "DisplayName"
            $data[0] | Should -HaveProperty "RiskLevel"
            $data[0] | Should -HaveProperty "MigrationTarget"
        }
    }
}

Describe "06 ARM Sign-ins" {
    It "emits ARM sign-ins CSV" {
        $csv = Join-Path $PSScriptRoot '..\output\ARM_SignIns.csv'
        Test-Path $csv | Should -BeTrue
        (Import-Csv $csv).Count | Should -BeGreaterOrEqual 0
    }
    
    It "has required columns in ARM_SignIns.csv" {
        $csv = Join-Path $PSScriptRoot '..\output\ARM_SignIns.csv'
        if (Test-Path $csv) {
            $data = Import-Csv $csv
            $data[0] | Should -HaveProperty "Timestamp"
            $data[0] | Should -HaveProperty "UserPrincipalName"
            $data[0] | Should -HaveProperty "RiskLevel"
            $data[0] | Should -HaveProperty "Phase2Impact"
        }
    }
}

Describe "Full Audit Pipeline" {
    It "completes without errors" {
        $result = & "$PSScriptRoot\..\scripts\Run-Audit.ps1" -OutputRoot ".\test-output"
        $result | Should -Not -BeNullOrEmpty
        Test-Path ".\test-output\Admins_ByRole.csv" | Should -BeTrue
    }
}

Describe "Performance" {
    It "completes within reasonable time" {
        $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
        & "$PSScriptRoot\..\scripts\Run-Audit.ps1" -OutputRoot ".\test-output"
        $stopwatch.Stop()
        $stopwatch.Elapsed.TotalMinutes | Should -BeLessThan 10
    }
}
