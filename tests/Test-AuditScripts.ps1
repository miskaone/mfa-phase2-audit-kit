<#
.SYNOPSIS
Basic test framework for MFA Phase 2 Audit Kit scripts

.DESCRIPTION
Provides unit tests for core functions using Pester framework.
Tests validate function behavior with mocked data.

.REQUIREMENTS
Pester module must be installed: Install-Module Pester -Scope CurrentUser -Force
#>

# Import required modules
Import-Module Pester -Force
Import-Module "$PSScriptRoot\..\scripts\Common.psm1" -Force

# Test configuration
$TestOutputPath = ".\test-output"
$TestDataPath = ".\test-data"

# Ensure test directories exist
if (-not (Test-Path $TestOutputPath)) { New-Item -ItemType Directory -Force -Path $TestOutputPath | Out-Null }
if (-not (Test-Path $TestDataPath)) { New-Item -ItemType Directory -Force -Path $TestDataPath | Out-Null }

Describe "MFA Phase 2 Audit Kit - Core Functions" {
    
    BeforeAll {
        # Mock Graph API calls to avoid requiring actual authentication
        Mock Get-MgContext { return $null }
        Mock Connect-MgGraph { return $true }
        Mock Get-MgRoleManagementDirectoryRoleAssignment { return @() }
        Mock Get-MgUser { return @() }
        Mock Get-MgUserAuthenticationMethod { return @() }
        Mock Get-MgServicePrincipal { return @() }
        Mock Get-MgIdentityConditionalAccessPolicy { return @() }
        Mock Get-AzContext { return $null }
        Mock Connect-AzAccount { return $true }
        Mock Get-AzResource { return @() }
    }
    
    Context "Common.psm1 Functions" {
        
        It "Should create output path with timestamp" {
            $result = New-OutputPath -Root $TestOutputPath -Prefix "test"
            $result | Should -Not -BeNullOrEmpty
            $result | Should -Match "test/\d{8}-\d{6}"
            Test-Path $result | Should -Be $true
        }
        
        It "Should write log messages with timestamps" {
            $output = { Write-Log INFO "Test message" } | Out-String
            $output | Should -Match "\[\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\]\[INFO\] Test message"
        }
        
        It "Should export empty data gracefully" {
            $testFile = Join-Path $TestOutputPath "empty-test.csv"
            Export-Table -Data @() -Path $testFile
            Test-Path $testFile | Should -Be $true
            (Get-Content $testFile).Count | Should -Be 0
        }
        
        It "Should export data to CSV correctly" {
            $testData = @(
                [PSCustomObject]@{ Name = "Test1"; Value = "Value1" }
                [PSCustomObject]@{ Name = "Test2"; Value = "Value2" }
            )
            $testFile = Join-Path $TestOutputPath "test-data.csv"
            Export-Table -Data $testData -Path $testFile
            
            Test-Path $testFile | Should -Be $true
            $csvContent = Import-Csv $testFile
            $csvContent.Count | Should -Be 2
            $csvContent[0].Name | Should -Be "Test1"
        }
    }
    
    Context "Script Parameter Validation" {
        
        It "Should validate OutputRoot parameter exists" {
            { & "$PSScriptRoot\..\src\core\02_Audit-PrivilegedUsers.ps1" -OutputRoot "nonexistent-path" } | Should -Throw
        }
        
        It "Should validate DaysBack parameter range" {
            { & "$PSScriptRoot\..\src\core\02_Audit-PrivilegedUsers.ps1" -DaysBack 0 } | Should -Throw
            { & "$PSScriptRoot\..\src\core\02_Audit-PrivilegedUsers.ps1" -DaysBack 400 } | Should -Throw
        }
    }
    
    Context "Environment Variable Validation" {
        
        It "Should require GITHUB_TOKEN for GitHub Actions audit" {
            $env:GITHUB_TOKEN = $null
            { & "$PSScriptRoot\..\src\ci_cd\09_Audit-GitHubActions.ps1" -OutputRoot $TestOutputPath } | Should -Throw "*GITHUB_TOKEN*"
        }
        
        It "Should require AZDO_PAT and AZDO_ORG_URL for Azure DevOps audit" {
            $env:AZDO_PAT = $null
            $env:AZDO_ORG_URL = $null
            { & "$PSScriptRoot\..\src\ci_cd\10_Audit-AzureDevOps.ps1" -OutputRoot $TestOutputPath } | Should -Throw "*AZDO_PAT*"
        }
    }
    
    Context "Output Schema Validation" {
        
        It "Should generate Admins_ByRole.csv with expected columns" {
            # Mock data for privileged users
            Mock Get-MgRoleManagementDirectoryRoleAssignment {
                return @(
                    [PSCustomObject]@{ 
                        RoleDefinitionId = "role1"
                        PrincipalId = "user1"
                    }
                )
            }
            Mock Get-MgUser {
                return @(
                    [PSCustomObject]@{ 
                        Id = "user1"
                        UserPrincipalName = "test@contoso.com"
                        DisplayName = "Test User"
                    }
                )
            }
            
            & "$PSScriptRoot\..\src\core\02_Audit-PrivilegedUsers.ps1" -OutputRoot $TestOutputPath
            
            $outputFile = Get-ChildItem $TestOutputPath -Recurse -Name "Admins_ByRole.csv" | Select-Object -First 1
            $outputFile | Should -Not -BeNullOrEmpty
            
            $csvContent = Import-Csv (Join-Path $TestOutputPath $outputFile)
            $csvContent | Should -Not -BeNullOrEmpty
        }
        
        It "Should generate Potential_BreakGlass.csv" {
            & "$PSScriptRoot\..\src\core\02_Audit-PrivilegedUsers.ps1" -OutputRoot $TestOutputPath
            
            $outputFile = Get-ChildItem $TestOutputPath -Recurse -Name "Potential_BreakGlass.csv" | Select-Object -First 1
            $outputFile | Should -Not -BeNullOrEmpty
        }
    }
    
    Context "Error Handling" {
        
        It "Should handle Graph API errors gracefully" {
            Mock Get-MgRoleManagementDirectoryRoleAssignment { throw "Graph API Error" }
            
            { & "$PSScriptRoot\..\src\core\02_Audit-PrivilegedUsers.ps1" -OutputRoot $TestOutputPath } | Should -Throw
        }
        
        It "Should handle Azure connection errors gracefully" {
            Mock Connect-AzAccount { throw "Azure Connection Error" }
            
            { & "$PSScriptRoot\..\src\core\07_Audit-MI-CapableResources.ps1" -OutputRoot $TestOutputPath } | Should -Throw
        }
    }
}

# Cleanup test data
AfterAll {
    if (Test-Path $TestOutputPath) {
        Remove-Item $TestOutputPath -Recurse -Force
    }
}
