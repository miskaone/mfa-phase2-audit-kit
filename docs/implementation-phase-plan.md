# Implementation Phase Plan - Graph API Integration

## Overview
This plan details the final implementation phase to replace TODO stubs with actual Graph API calls and data processing logic.

## Current Status
- ✅ **Structure Complete**: All scripts have proper error handling, logging, and validation
- ✅ **Testing Framework**: Comprehensive Pester tests with mocking
- ✅ **Documentation**: Complete function documentation and examples
- ⚠️ **Core Logic**: TODO stubs need Graph API implementation

---

## Phase 5: Graph API Implementation

### 5.1 Priority Order (Based on Dependencies)

#### **Tier 1: Foundation Scripts (Week 1)**
1. **02_Audit-PrivilegedUsers.ps1** - Core admin enumeration
2. **04_Audit-ConditionalAccess.ps1** - CA policy analysis
3. **05_Audit-AdminAuthMethods.ps1** - Auth method enumeration

#### **Tier 2: Service Account Analysis (Week 2)**
4. **03_Audit-ServicePrincipals.ps1** - Service principal credentials
5. **06_Audit-ARM-WriteSignIns.ps1** - Sign-in log analysis

#### **Tier 3: Resource Analysis (Week 3)**
6. **07_Audit-MI-CapableResources.ps1** - Azure resource enumeration
7. **08_Generate-Recommendations.ps1** - Data aggregation and reporting

#### **Tier 4: CI/CD Integration (Week 4)**
8. **09_Audit-GitHubActions.ps1** - GitHub API integration
9. **10_Audit-AzureDevOps.ps1** - Azure DevOps API integration
10. **11_Generate-Extended-Recommendations.ps1** - Extended reporting

---

## 1. Detailed Requirements

### 1.1 Core Script Requirements

#### **02_Audit-PrivilegedUsers.ps1**
**Purpose**: Enumerate all privileged users and identify break-glass accounts

**Technical Requirements**:
- **Graph API Calls**:
  - `Get-MgRoleManagementDirectoryRoleDefinition` - Get all Azure AD roles
  - `Get-MgRoleManagementDirectoryRoleAssignment` - Get role assignments
  - `Get-MgUser` - Get user details and MFA status
  - `Get-MgUserAuthenticationMethod` - Get authentication methods
  - `Get-MgUserSignInActivity` - Get recent sign-in activity

**Data Schema**:
```powershell
[PSCustomObject]@{
    RoleId = "string"                    # Role definition ID
    RoleName = "string"                  # Human-readable role name
    UserId = "string"                    # User object ID
    UserPrincipalName = "string"         # UPN
    DisplayName = "string"               # Display name
    IsPrivileged = $true/$false          # Has any privileged role
    MFA_Enabled = $true/$false           # MFA status
    LastSignIn = "datetime"              # Last sign-in timestamp
    IsBreakGlass = $true/$false          # Potential break-glass account
    RiskLevel = "Low|Medium|High|Critical" # Calculated risk level
    AuthMethods = @("password", "fido2") # Available auth methods
    ExcludedFromCA = $true/$false        # Excluded from Conditional Access
    ExceptionsPolicyName = "string"      # Name of CA policy with exceptions
}
```

**Break-Glass Detection Logic**:
```powershell
function Test-BreakGlassAccount {
    param($User, $AuthMethods, $CAExclusions)
    
    $indicators = @()
    
    # High privilege + no MFA
    if ($User.IsPrivileged -and -not $User.MFA_Enabled) {
        $indicators += "High privilege without MFA"
    }
    
    # Excluded from Conditional Access
    if ($CAExclusions) {
        $indicators += "Excluded from Conditional Access"
    }
    
    # Only password authentication
    if ($AuthMethods -eq @("password")) {
        $indicators += "Password-only authentication"
    }
    
    # No recent sign-ins (potential dormant account)
    if ($User.LastSignIn -lt (Get-Date).AddDays(-30)) {
        $indicators += "No recent sign-ins"
    }
    
    return @{
        IsBreakGlass = $indicators.Count -gt 0
        Indicators = $indicators
        RiskScore = $indicators.Count * 25  # 0-100 scale
    }
}
```

**Error Handling**:
- Handle Graph API rate limiting (429 errors)
- Retry logic with exponential backoff
- Graceful degradation for missing permissions
- Log all API failures with context

#### **03_Audit-ServicePrincipals.ps1**
**Purpose**: Audit service principals for credential-based authentication

**Technical Requirements**:
- **Graph API Calls**:
  - `Get-MgServicePrincipal` - Get all service principals
  - `Get-MgServicePrincipalAppRoleAssignment` - Get app role assignments
  - `Get-MgServicePrincipalKey` - Get client secrets and certificates
  - `Get-MgServicePrincipalOAuth2PermissionGrant` - Get OAuth grants

**Data Schema**:
```powershell
[PSCustomObject]@{
    AppId = "string"                     # Application ID
    DisplayName = "string"               # Service principal name
    AppType = "string"                   # Application type
    IsPrivileged = $true/$false          # Has privileged roles
    HasClientSecret = $true/$false       # Has client secret
    HasCertificate = $true/$false        # Has certificate
    SecretExpiry = "datetime"            # Secret expiry date
    CertificateExpiry = "datetime"       # Certificate expiry date
    OAuthGrants = @("string")           # OAuth permission grants
    RiskLevel = "Low|Medium|High|Critical" # Calculated risk level
    MigrationTarget = "ManagedIdentity|ServicePrincipal|None" # Recommended migration
    LastUsed = "datetime"                # Last activity timestamp
}
```

**Credential Analysis Logic**:
```powershell
function Test-ServicePrincipalCredentials {
    param($ServicePrincipal, $Secrets, $Certificates)
    
    $risks = @()
    
    # Expired credentials
    $expiredSecrets = $Secrets | Where-Object { $_.EndDateTime -lt (Get-Date) }
    if ($expiredSecrets) {
        $risks += "Expired client secrets"
    }
    
    # Long-lived secrets (>1 year)
    $longLivedSecrets = $Secrets | Where-Object { $_.EndDateTime -gt (Get-Date).AddYears(1) }
    if ($longLivedSecrets) {
        $risks += "Long-lived client secrets"
    }
    
    # No certificate authentication
    if (-not $Certificates) {
        $risks += "No certificate authentication"
    }
    
    # High privilege without strong auth
    if ($ServicePrincipal.IsPrivileged -and -not $Certificates) {
        $risks += "High privilege without certificate auth"
    }
    
    return @{
        RiskLevel = switch ($risks.Count) {
            0 { "Low" }
            1-2 { "Medium" }
            3-4 { "High" }
            default { "Critical" }
        }
        Risks = $risks
        MigrationTarget = if ($ServicePrincipal.IsPrivileged) { "ManagedIdentity" } else { "ServicePrincipal" }
    }
}
```

#### **04_Audit-ConditionalAccess.ps1**
**Purpose**: Analyze Conditional Access policies for MFA enforcement gaps

**Technical Requirements**:
- **Graph API Calls**:
  - `Get-MgIdentityConditionalAccessPolicy` - Get all CA policies
  - `Get-MgIdentityConditionalAccessPolicyTemplate` - Get policy templates
  - `Get-MgDirectorySetting` - Get directory settings

**Data Schema**:
```powershell
[PSCustomObject]@{
    PolicyId = "string"                  # Policy ID
    DisplayName = "string"               # Policy name
    State = "enabled|disabled|enabledForReportingButNotEnforced" # Policy state
    AppliesTo = "string"                 # Target users/groups
    Conditions = "string"                # Policy conditions
    ClientApps = "string"                # Client app types
    SignInRisk = "string"                # Sign-in risk level
    SessionControls = "string"           # Session controls
    EffectiveMFAEnforced = $true/$false  # Effectively enforces MFA
    HasRiskyExclusions = $true/$false    # Has risky exclusions
    ExcludedUsers = @("string")          # Excluded user UPNs
    ExcludedGroups = @("string")         # Excluded group names
    RiskLevel = "Low|Medium|High|Critical" # Policy risk level
    Recommendations = @("string")        # Improvement recommendations
}
```

**Policy Analysis Logic**:
```powershell
function Test-ConditionalAccessPolicy {
    param($Policy)
    
    $risks = @()
    $recommendations = @()
    
    # Disabled policies
    if ($Policy.State -eq "disabled") {
        $risks += "Policy is disabled"
        $recommendations += "Enable policy or remove if no longer needed"
    }
    
    # No MFA requirement
    if (-not $Policy.EffectiveMFAEnforced) {
        $risks += "Does not enforce MFA"
        $recommendations += "Add MFA requirement to policy"
    }
    
    # Risky exclusions
    if ($Policy.HasRiskyExclusions) {
        $risks += "Has risky exclusions"
        $recommendations += "Review and minimize exclusions"
    }
    
    # Too broad scope
    if ($Policy.AppliesTo -eq "All users") {
        $risks += "Applies to all users"
        $recommendations += "Consider more targeted scope"
    }
    
    return @{
        RiskLevel = switch ($risks.Count) {
            0 { "Low" }
            1-2 { "Medium" }
            3-4 { "High" }
            default { "Critical" }
        }
        Risks = $risks
        Recommendations = $recommendations
    }
}
```

#### **05_Audit-AdminAuthMethods.ps1**
**Purpose**: Audit authentication methods for privileged users

**Technical Requirements**:
- **Graph API Calls**:
  - `Get-MgUserAuthenticationMethod` - Get user auth methods
  - `Get-MgUserAuthenticationFido2Method` - Get FIDO2 methods
  - `Get-MgUserAuthenticationPhoneMethod` - Get phone methods
  - `Get-MgUserAuthenticationPasswordMethod` - Get password methods

**Data Schema**:
```powershell
[PSCustomObject]@{
    UserId = "string"                    # User object ID
    UserPrincipalName = "string"         # UPN
    DisplayName = "string"               # Display name
    IsPrivileged = $true/$false          # Has privileged roles
    MFA_Enabled = $true/$false           # MFA status
    AuthMethods = @("string")            # Available auth methods
    FIDO2_Enabled = $true/$false         # FIDO2/passkey enabled
    Phone_Enabled = $true/$false         # Phone authentication
    Password_Enabled = $true/$false      # Password authentication
    StrongAuthCount = 0                  # Count of strong auth methods
    WeakAuthCount = 0                    # Count of weak auth methods
    RiskLevel = "Low|Medium|High|Critical" # Calculated risk level
    Recommendations = @("string")        # Improvement recommendations
}
```

**Authentication Method Analysis**:
```powershell
function Test-AuthenticationMethods {
    param($User, $AuthMethods)
    
    $strongMethods = @("fido2", "passkey", "certificate")
    $weakMethods = @("password", "sms", "voice")
    
    $strongCount = ($AuthMethods | Where-Object { $_ -in $strongMethods }).Count
    $weakCount = ($AuthMethods | Where-Object { $_ -in $weakMethods }).Count
    
    $risks = @()
    $recommendations = @()
    
    # No strong authentication
    if ($strongCount -eq 0) {
        $risks += "No strong authentication methods"
        $recommendations += "Enable FIDO2/passkey authentication"
    }
    
    # Only password authentication
    if ($AuthMethods -eq @("password")) {
        $risks += "Password-only authentication"
        $recommendations += "Add additional authentication methods"
    }
    
    # No MFA
    if (-not $User.MFA_Enabled) {
        $risks += "MFA not enabled"
        $recommendations += "Enable MFA for this user"
    }
    
    return @{
        StrongAuthCount = $strongCount
        WeakAuthCount = $weakCount
        RiskLevel = switch ($risks.Count) {
            0 { "Low" }
            1-2 { "Medium" }
            3-4 { "High" }
            default { "Critical" }
        }
        Risks = $risks
        Recommendations = $recommendations
    }
}
```

#### **06_Audit-ARM-WriteSignIns.ps1**
**Purpose**: Analyze ARM sign-ins for Phase 2 impact

**Technical Requirements**:
- **Graph API Calls**:
  - `Get-MgAuditLogSignIn` - Get sign-in logs
  - `Get-MgAuditLogDirectoryAudit` - Get directory audit logs
  - `Get-MgAuditLogProvisioning` - Get provisioning logs

**Data Schema**:
```powershell
[PSCustomObject]@{
    TenantId = "string"                  # Tenant ID
    SubscriptionId = "string"            # Azure subscription ID
    CorrelationId = "string"             # Correlation ID
    Timestamp = "datetime"               # Sign-in timestamp
    UserPrincipalName = "string"         # User UPN
    IPAddress = "string"                 # IP address
    UserAgent = "string"                 # User agent
    ClientAppUsed = "string"             # Client application
    ResourceId = "string"                # Azure resource ID
    Action = "string"                    # Action performed
    OperationName = "string"             # Operation name
    PrincipalId = "string"               # Principal ID
    AppId = "string"                     # Application ID
    IsInteractive = $true/$false         # Interactive sign-in
    IsServicePrincipal = $true/$false    # Service principal sign-in
    MFA_Required = $true/$false          # MFA required
    MFA_Completed = $true/$false         # MFA completed
    RiskLevel = "Low|Medium|High|Critical" # Calculated risk level
    Phase2Impact = "string"              # Phase 2 impact assessment
}
```

**Sign-in Analysis Logic**:
```powershell
function Test-ARMSignIn {
    param($SignIn)
    
    $risks = @()
    $phase2Impact = "None"
    
    # Non-interactive without MFA
    if (-not $SignIn.IsInteractive -and -not $SignIn.MFA_Completed) {
        $risks += "Non-interactive without MFA"
        $phase2Impact = "High - Will fail in Phase 2"
    }
    
    # Service principal with password
    if ($SignIn.IsServicePrincipal -and $SignIn.ClientAppUsed -eq "Other clients") {
        $risks += "Service principal using password"
        $phase2Impact = "High - Needs migration to Managed Identity"
    }
    
    # High privilege operations
    $highPrivilegeOps = @("Microsoft.Resources/subscriptions/write", "Microsoft.Authorization/roleAssignments/write")
    if ($SignIn.OperationName -in $highPrivilegeOps -and -not $SignIn.MFA_Completed) {
        $risks += "High privilege operation without MFA"
        $phase2Impact = "Critical - Will fail in Phase 2"
    }
    
    return @{
        RiskLevel = switch ($risks.Count) {
            0 { "Low" }
            1-2 { "Medium" }
            3-4 { "High" }
            default { "Critical" }
        }
        Risks = $risks
        Phase2Impact = $phase2Impact
    }
}
```

#### **07_Audit-MI-CapableResources.ps1**
**Purpose**: Identify Azure resources that can use Managed Identities

**Technical Requirements**:
- **Azure PowerShell Calls**:
  - `Get-AzResource` - Get all Azure resources
  - `Get-AzResourceGroup` - Get resource groups
  - `Get-AzSubscription` - Get subscriptions

**Data Schema**:
```powershell
[PSCustomObject]@{
    ResourceId = "string"                # Resource ID
    ResourceName = "string"              # Resource name
    ResourceType = "string"              # Resource type
    ResourceGroup = "string"             # Resource group
    SubscriptionId = "string"            # Subscription ID
    Location = "string"                  # Azure region
    ManagedIdentityType = "None|SystemAssigned|UserAssigned|Both" # MI type
    UserAssignedIdentityIds = @("string") # User-assigned identity IDs
    PotentialMigrationTarget = $true/$false # Can migrate to MI
    MigrationComplexity = "Low|Medium|High" # Migration complexity
    CurrentAuthMethod = "string"         # Current authentication method
    Recommendations = @("string")        # Migration recommendations
}
```

**Managed Identity Analysis**:
```powershell
function Test-ManagedIdentityCapability {
    param($Resource)
    
    $miCapableTypes = @(
        "Microsoft.Compute/virtualMachines",
        "Microsoft.Web/sites",
        "Microsoft.Logic/workflows",
        "Microsoft.DataFactory/factories"
    )
    
    $isCapable = $Resource.ResourceType -in $miCapableTypes
    $complexity = "Low"
    $recommendations = @()
    
    if ($isCapable) {
        # Check current authentication method
        if ($Resource.CurrentAuthMethod -eq "ServicePrincipal") {
            $complexity = "Medium"
            $recommendations += "Migrate from Service Principal to Managed Identity"
        } elseif ($Resource.CurrentAuthMethod -eq "UserAssigned") {
            $complexity = "Low"
            $recommendations += "Already using Managed Identity"
        } else {
            $complexity = "High"
            $recommendations += "Implement Managed Identity authentication"
        }
    } else {
        $recommendations += "Resource type does not support Managed Identity"
    }
    
    return @{
        IsCapable = $isCapable
        Complexity = $complexity
        Recommendations = $recommendations
    }
}
```

#### **08_Generate-Recommendations.ps1**
**Purpose**: Generate comprehensive audit findings and recommendations

**Technical Requirements**:
- **Data Aggregation**: Combine results from all audit scripts
- **Risk Scoring**: Calculate overall risk scores
- **Report Generation**: Create markdown report with findings

**Data Schema**:
```powershell
[PSCustomObject]@{
    FindingId = "string"                 # Unique finding ID
    Category = "string"                  # Finding category
    Severity = "Low|Medium|High|Critical" # Finding severity
    Title = "string"                     # Finding title
    Description = "string"               # Finding description
    Impact = "string"                    # Business impact
    Recommendation = "string"            # Recommended action
    Priority = 1-5                       # Priority score
    Effort = "Low|Medium|High"           # Implementation effort
    Timeline = "string"                  # Recommended timeline
    Dependencies = @("string")           # Required dependencies
}
```

**Recommendation Generation Logic**:
```powershell
function Generate-Findings {
    param($AuditResults)
    
    $findings = @()
    
    # Critical findings
    $criticalUsers = $AuditResults.PrivilegedUsers | Where-Object { $_.RiskLevel -eq "Critical" }
    if ($criticalUsers) {
        $findings += [PSCustomObject]@{
            FindingId = "CRIT-001"
            Category = "Privileged Access"
            Severity = "Critical"
            Title = "Critical privileged users without MFA"
            Description = "Found $($criticalUsers.Count) privileged users without MFA"
            Impact = "High risk of account compromise"
            Recommendation = "Enable MFA for all privileged users immediately"
            Priority = 1
            Effort = "Low"
            Timeline = "Immediate"
        }
    }
    
    # High findings
    $breakGlassAccounts = $AuditResults.PrivilegedUsers | Where-Object { $_.IsBreakGlass -eq $true }
    if ($breakGlassAccounts) {
        $findings += [PSCustomObject]@{
            FindingId = "HIGH-001"
            Category = "Break-Glass Accounts"
            Severity = "High"
            Title = "Potential break-glass accounts identified"
            Description = "Found $($breakGlassAccounts.Count) potential break-glass accounts"
            Impact = "Security risk if accounts are compromised"
            Recommendation = "Review and secure break-glass accounts"
            Priority = 2
            Effort = "Medium"
            Timeline = "1 week"
        }
    }
    
    return $findings
}
```

### 1.2 Error Handling Requirements

#### **Graph API Error Handling**
```powershell
function Invoke-GraphApiWithRetry {
    param(
        [scriptblock]$ApiCall,
        [int]$MaxRetries = 3,
        [int]$BaseDelay = 1000
    )
    
    $attempt = 0
    do {
        try {
            return & $ApiCall
        }
        catch {
            $attempt++
            if ($_.Exception.Response.StatusCode -eq 429) {
                # Rate limiting - exponential backoff
                $delay = $BaseDelay * [math]::Pow(2, $attempt - 1)
                Write-Log WARN "Rate limited, waiting $delay ms before retry $attempt/$MaxRetries"
                Start-Sleep -Milliseconds $delay
            }
            elseif ($_.Exception.Response.StatusCode -eq 403) {
                # Insufficient permissions
                Write-Log ERROR "Insufficient permissions: $($_.Exception.Message)"
                throw "Insufficient permissions to access Graph API"
            }
            else {
                # Other errors
                Write-Log ERROR "Graph API error: $($_.Exception.Message)"
                if ($attempt -eq $MaxRetries) {
                    throw "Graph API call failed after $MaxRetries attempts: $($_.Exception.Message)"
                }
            }
        }
    } while ($attempt -lt $MaxRetries)
}
```

#### **Data Validation**
```powershell
function Test-RequiredData {
    param($Data, $RequiredFields)
    
    $missingFields = @()
    foreach ($field in $RequiredFields) {
        if (-not $Data.PSObject.Properties.Name -contains $field) {
            $missingFields += $field
        }
    }
    
    if ($missingFields) {
        throw "Missing required fields: $($missingFields -join ', ')"
    }
}
```

### 1.3 Performance Requirements

#### **Pagination Handling**
```powershell
function Get-AllGraphResults {
    param($ApiCall, $Filter = $null)
    
    $allResults = @()
    $skipToken = $null
    
    do {
        $params = @{}
        if ($Filter) { $params.Filter = $Filter }
        if ($skipToken) { $params.SkipToken = $skipToken }
        
        $response = & $ApiCall @params
        $allResults += $response.Value
        
        $skipToken = $response.'@odata.nextLink' -replace '.*\$skiptoken=', ''
    } while ($skipToken)
    
    return $allResults
}
```

#### **Batch Processing**
```powershell
function Process-Batch {
    param($Items, $BatchSize = 100, $ProcessFunction)
    
    $batches = @()
    for ($i = 0; $i -lt $Items.Count; $i += $BatchSize) {
        $batch = $Items[$i..($i + $BatchSize - 1)]
        $batches += $batch
    }
    
    $results = @()
    foreach ($batch in $batches) {
        $batchResults = & $ProcessFunction $batch
        $results += $batchResults
    }
    
    return $results
}
```

### 1.4 Security Requirements

#### **Credential Handling**
```powershell
function Get-SecureCredential {
    param($CredentialName)
    
    $credential = Get-StoredCredential -Target $CredentialName
    if (-not $credential) {
        $credential = Get-Credential -Message "Enter credentials for $CredentialName"
        Set-StoredCredential -Target $CredentialName -Credential $credential
    }
    
    return $credential
}
```

#### **Data Sanitization**
```powershell
function Sanitize-OutputData {
    param($Data)
    
    # Remove sensitive fields
    $sensitiveFields = @("Password", "Secret", "Key", "Token")
    foreach ($item in $Data) {
        foreach ($field in $sensitiveFields) {
            if ($item.PSObject.Properties.Name -contains $field) {
                $item.$field = "***REDACTED***"
            }
        }
    }
    
    return $Data
}
```

## 2. Implementation Timeline

### **Week 1: Core Infrastructure**
- [ ] Implement error handling framework
- [ ] Add data validation functions
- [ ] Create pagination utilities
- [ ] Set up logging framework

### **Week 2: Critical Scripts**
- [ ] `02_Audit-PrivilegedUsers.ps1` - Complete implementation
- [ ] `04_Audit-ConditionalAccess.ps1` - Complete implementation
- [ ] `08_Generate-Recommendations.ps1` - Complete implementation

### **Week 3: High Priority Scripts**
- [ ] `03_Audit-ServicePrincipals.ps1` - Complete implementation
- [ ] `06_Audit-ARM-WriteSignIns.ps1` - Complete implementation
- [ ] `05_Audit-AdminAuthMethods.ps1` - Complete implementation

### **Week 4: Remaining Scripts**
- [ ] `07_Audit-MI-CapableResources.ps1` - Complete implementation
- [ ] `09_Audit-GitHubActions.ps1` - Complete implementation
- [ ] `10_Audit-AzureDevOps.ps1` - Complete implementation

### **Week 5: Testing & Validation**
- [ ] Unit testing for all functions
- [ ] Integration testing with real tenant
- [ ] Performance optimization
- [ ] Documentation updates

## 3. Success Criteria

### **Functional Requirements**
- [ ] All scripts return real data (not empty arrays)
- [ ] Break-glass account detection works accurately
- [ ] Risk scoring is consistent and meaningful
- [ ] Recommendations are actionable and prioritized
- [ ] Output schemas match example files

### **Non-Functional Requirements**
- [ ] Scripts complete within 5 minutes for typical tenant
- [ ] Error handling prevents script crashes
- [ ] Logging provides sufficient debugging information
- [ ] Memory usage stays under 1GB
- [ ] All Graph API calls respect rate limits

### **Quality Requirements**
- [ ] Code coverage > 80%
- [ ] All functions have comprehensive documentation
- [ ] Error messages are user-friendly
- [ ] Output is consistent across all scripts
- [ ] Performance is acceptable for production use

## 4. Risk Mitigation

### **Technical Risks**
- **Graph API Rate Limiting**: Implement exponential backoff and retry logic
- **Permission Issues**: Graceful degradation and clear error messages
- **Data Inconsistency**: Validate data before processing
- **Memory Issues**: Implement pagination and batch processing

### **Business Risks**
- **Incomplete Data**: Clear indication of what data is missing
- **False Positives**: Conservative risk scoring with clear explanations
- **Performance Issues**: Progress indicators and timeout handling
- **Security Concerns**: Sanitize sensitive data in outputs

## 5. Testing Strategy

### **Unit Testing**
```powershell
Describe "Get-PrivilegedUsers" {
    It "Should return privileged users with correct schema" {
        $result = Get-PrivilegedUsers
        $result | Should -Not -BeNullOrEmpty
        $result[0] | Should -HaveProperty "RoleName"
        $result[0] | Should -HaveProperty "UserPrincipalName"
        $result[0] | Should -HaveProperty "MFA_Enabled"
    }
}
```

### **Integration Testing**
```powershell
Describe "Full Audit Pipeline" {
    It "Should complete without errors" {
        $result = .\scripts\Run-Audit.ps1 -OutputRoot .\test-output
        $result | Should -Not -BeNullOrEmpty
        Test-Path ".\test-output\Admins_ByRole.csv" | Should -Be $true
    }
}
```

### **Performance Testing**
```powershell
Describe "Performance" {
    It "Should complete within 5 minutes" {
        $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
        .\scripts\Run-Audit.ps1 -OutputRoot .\test-output
        $stopwatch.Stop()
        $stopwatch.Elapsed.TotalMinutes | Should -BeLessThan 5
    }
}
```

## Detailed Implementation Guide

### 5.2 Script-by-Script Implementation

#### **02_Audit-PrivilegedUsers.ps1**

**Current State**: TODO stubs for role enumeration and auth methods
**Target State**: Complete Graph API integration

**Implementation Steps**:
```powershell
function Get-PrivilegedUsers {
    <#
    .SYNOPSIS
    Retrieves users with privileged directory roles
    
    .DESCRIPTION
    Enumerates all directory roles and their members, returning user details
    with role information for MFA posture analysis
    
    .OUTPUTS
    PSCustomObject[] - Array of user objects with role information
    #>
    
    try {
        Write-Progress -Activity "Enumerating Privileged Users" -Status "Getting directory roles" -Current 1 -Total 3
        
        # Get all directory roles
        $roles = Get-MgRoleManagementDirectoryRoleDefinition -All
        Write-Log INFO "Found $($roles.Count) directory roles"
        
        Write-Progress -Activity "Enumerating Privileged Users" -Status "Getting role assignments" -Current 2 -Total 3
        
        $privilegedUsers = @()
        foreach ($role in $roles) {
            $assignments = Get-MgRoleManagementDirectoryRoleAssignment -Filter "roleDefinitionId eq '$($role.Id)'" -All
            Write-Log INFO "Role '$($role.DisplayName)' has $($assignments.Count) assignments"
            
            foreach ($assignment in $assignments) {
                if ($assignment.PrincipalType -eq "User") {
                    try {
                        $user = Get-MgUser -UserId $assignment.PrincipalId -Property "Id,UserPrincipalName,DisplayName,AccountEnabled"
                        $privilegedUsers += [PSCustomObject]@{
                            RoleId = $role.Id
                            RoleName = $role.DisplayName
                            UserId = $user.Id
                            UserPrincipalName = $user.UserPrincipalName
                            DisplayName = $user.DisplayName
                            AccountEnabled = $user.AccountEnabled
                        }
                    } catch {
                        Write-Log WARN "Failed to get user details for $($assignment.PrincipalId): $($_.Exception.Message)"
                    }
                }
            }
        }
        
        Write-Progress -Activity "Enumerating Privileged Users" -Status "Complete" -Current 3 -Total 3
        return $privilegedUsers
        
    } catch {
        Write-Log ERROR "Failed to enumerate privileged users: $($_.Exception.Message)"
        throw
    }
}

function Join-AuthMethods {
    <#
    .SYNOPSIS
    Enriches user objects with authentication method information
    
    .DESCRIPTION
    Adds MFA status and authentication method details to user objects
    for comprehensive security posture analysis
    
    .PARAMETER Users
    Array of user objects to enrich with auth method data
    
    .OUTPUTS
    PSCustomObject[] - Enriched user objects with auth method information
    #>
    param([Object[]]$Users)
    
    $enrichedUsers = @()
    $total = $Users.Count
    $current = 0
    
    foreach ($user in $Users) {
        $current++
        Write-Progress -Activity "Enriching Auth Methods" -Status "Processing $($user.UserPrincipalName)" -Current $current -Total $total
        
        try {
            # Get authentication methods
            $authMethods = Get-MgUserAuthenticationMethod -UserId $user.UserId -All
            
            # Analyze auth methods
            $fido2 = $authMethods | Where-Object { $_.ODataType -eq "#microsoft.graph.fido2AuthenticationMethod" }
            $passkey = $authMethods | Where-Object { $_.ODataType -eq "#microsoft.graph.microsoftAuthenticatorAuthenticationMethod" -and $_.IsPasskey -eq $true }
            $authenticatorApp = $authMethods | Where-Object { $_.ODataType -eq "#microsoft.graph.microsoftAuthenticatorAuthenticationMethod" }
            $phone = $authMethods | Where-Object { $_.ODataType -eq "#microsoft.graph.phoneAuthenticationMethod" }
            
            # Check if passwordless is enabled
            $passwordlessEnabled = ($fido2.Count -gt 0) -or ($passkey.Count -gt 0)
            
            # Determine effective MFA status
            $hasStrongAuth = ($fido2.Count -gt 0) -or ($passkey.Count -gt 0) -or ($authenticatorApp.Count -gt 0)
            
            $enrichedUsers += [PSCustomObject]@{
                RoleId = $user.RoleId
                RoleName = $user.RoleName
                UserId = $user.UserId
                UserPrincipalName = $user.UserPrincipalName
                DisplayName = $user.DisplayName
                AccountEnabled = $user.AccountEnabled
                MFA_Enabled = $hasStrongAuth
                AuthMethod = if ($fido2.Count -gt 0) { "FIDO2" } elseif ($passkey.Count -gt 0) { "Passkey" } elseif ($authenticatorApp.Count -gt 0) { "Authenticator App" } elseif ($phone.Count -gt 0) { "Phone" } else { "Password" }
                LastSignIn = $null  # Would need sign-in logs
                IsBreakGlass = $false  # Will be determined by Test-BreakGlassAccount
            }
            
        } catch {
            Write-Log WARN "Failed to get auth methods for $($user.UserPrincipalName): $($_.Exception.Message)"
            # Add user with minimal data
            $enrichedUsers += [PSCustomObject]@{
                RoleId = $user.RoleId
                RoleName = $user.RoleName
                UserId = $user.UserId
                UserPrincipalName = $user.UserPrincipalName
                DisplayName = $user.DisplayName
                AccountEnabled = $user.AccountEnabled
                MFA_Enabled = $false
                AuthMethod = "Unknown"
                LastSignIn = $null
                IsBreakGlass = $false
            }
        }
    }
    
    return $enrichedUsers
}

function Test-BreakGlassAccount {
    <#
    .SYNOPSIS
    Identifies potential break-glass accounts based on security patterns
    
    .DESCRIPTION
    Analyzes user accounts for break-glass indicators including:
    - Excluded from Conditional Access policies
    - High-privilege accounts without MFA
    - Emergency access accounts
    
    .PARAMETER Users
    Array of user objects to analyze for break-glass patterns
    
    .OUTPUTS
    PSCustomObject[] - Array of break-glass account objects
    #>
    param([Object[]]$Users)
    
    $breakGlassAccounts = @()
    
    foreach ($user in $Users) {
        $isBreakGlass = $false
        $reason = @()
        
        # Check for high-privilege without MFA
        if ($user.RoleName -in @("Global Administrator", "Privileged Role Administrator", "Security Administrator") -and -not $user.MFA_Enabled) {
            $isBreakGlass = $true
            $reason += "High-privilege account without MFA"
        }
        
        # Check for emergency access patterns
        if ($user.UserPrincipalName -match "breakglass|emergency|admin" -and -not $user.MFA_Enabled) {
            $isBreakGlass = $true
            $reason += "Emergency access account without MFA"
        }
        
        # Check for password-only authentication
        if ($user.AuthMethod -eq "Password") {
            $isBreakGlass = $true
            $reason += "Password-only authentication"
        }
        
        if ($isBreakGlass) {
            $breakGlassAccounts += [PSCustomObject]@{
                UserId = $user.UserId
                UserPrincipalName = $user.UserPrincipalName
                DisplayName = $user.DisplayName
                ReasonFlagged = ($reason -join "; ")
                MFA_Enabled = $user.MFA_Enabled
                IsExcludedFromCA = $false  # Would need CA policy analysis
                ExceptionsPolicyName = $null
                IsBreakGlass = $true
            }
        }
    }
    
    return $breakGlassAccounts
}
```

#### **04_Audit-ConditionalAccess.ps1**

**Implementation**:
```powershell
function Get-ConditionalAccessPolicies {
    <#
    .SYNOPSIS
    Retrieves Conditional Access policies and analyzes their configuration
    
    .DESCRIPTION
    Gets all CA policies and analyzes their MFA enforcement, exclusions,
    and potential security risks
    
    .OUTPUTS
    PSCustomObject[] - Array of CA policy objects with analysis
    #>
    
    try {
        Write-Progress -Activity "Analyzing CA Policies" -Status "Getting policies" -Current 1 -Total 2
        
        $policies = Get-MgIdentityConditionalAccessPolicy -All
        Write-Log INFO "Found $($policies.Count) Conditional Access policies"
        
        Write-Progress -Activity "Analyzing CA Policies" -Status "Analyzing policy configuration" -Current 2 -Total 2
        
        $analyzedPolicies = @()
        foreach ($policy in $policies) {
            # Analyze grant controls
            $requiresMFA = $false
            $grantControls = @()
            
            if ($policy.GrantControls) {
                $grantControls = $policy.GrantControls.GrantControlTypes
                $requiresMFA = $grantControls -contains "mfa"
            }
            
            # Analyze exclusions
            $exclusions = @()
            if ($policy.ExcludeUsers) {
                $exclusions += "Users: $($policy.ExcludeUsers.Count)"
            }
            if ($policy.ExcludeGroups) {
                $exclusions += "Groups: $($policy.ExcludeGroups.Count)"
            }
            if ($policy.ExcludeApplications) {
                $exclusions += "Applications: $($policy.ExcludeApplications.Count)"
            }
            
            # Determine if exclusions are risky
            $hasRiskyExclusions = $exclusions.Count -gt 0 -and $requiresMFA
            
            $analyzedPolicies += [PSCustomObject]@{
                PolicyId = $policy.Id
                PolicyName = $policy.DisplayName
                State = $policy.State
                AppliesTo = "Users"  # Simplified for now
                Conditions = "Any"  # Simplified for now
                ClientApps = "All"  # Simplified for now
                GrantControls = ($grantControls -join ", ")
                SessionControls = "None"  # Simplified for now
                Exclusions = ($exclusions -join "; ")
                LastModified = $policy.ModifiedDateTime
                EffectiveMFAEnforced = $requiresMFA
                HasRiskyExclusions = $hasRiskyExclusions
            }
        }
        
        return $analyzedPolicies
        
    } catch {
        Write-Log ERROR "Failed to analyze CA policies: $($_.Exception.Message)"
        throw
    }
}
```

### 5.3 Implementation Patterns

#### **Common Graph API Patterns**

1. **Error Handling**:
```powershell
try {
    $result = Get-MgUser -UserId $userId -ErrorAction Stop
} catch {
    if ($_.Exception.Message -match "404") {
        Write-Log WARN "User not found: $userId"
        continue
    } else {
        Write-Log ERROR "Failed to get user $userId`: $($_.Exception.Message)"
        throw
    }
}
```

2. **Progress Reporting**:
```powershell
$total = $items.Count
$current = 0
foreach ($item in $items) {
    $current++
    Write-Progress -Activity "Processing Items" -Status "Item $current of $total" -Current $current -Total $total
    # Process item
}
```

3. **Rate Limiting**:
```powershell
# Add delay between API calls to respect rate limits
Start-Sleep -Milliseconds 100
```

4. **Batch Processing**:
```powershell
# Process items in batches to avoid overwhelming the API
$batchSize = 50
for ($i = 0; $i -lt $items.Count; $i += $batchSize) {
    $batch = $items[$i..($i + $batchSize - 1)]
    # Process batch
}
```

### 5.4 Testing Strategy

#### **Unit Tests for Each Function**
```powershell
Describe "Get-PrivilegedUsers" {
    It "Should return users with roles" {
        Mock Get-MgRoleManagementDirectoryRoleDefinition { return @($mockRole) }
        Mock Get-MgRoleManagementDirectoryRoleAssignment { return @($mockAssignment) }
        Mock Get-MgUser { return @($mockUser) }
        
        $result = Get-PrivilegedUsers
        $result | Should -Not -BeNullOrEmpty
        $result.Count | Should -Be 1
        $result[0].RoleName | Should -Be "Global Administrator"
    }
}
```

#### **Integration Tests**
```powershell
Describe "End-to-End Script Execution" {
    It "Should generate expected outputs" {
        Mock Get-MgContext { return $mockContext }
        Mock Connect-MgGraph { return $true }
        # ... other mocks
        
        & ".\src\core\02_Audit-PrivilegedUsers.ps1" -OutputRoot ".\test-output"
        
        Test-Path ".\test-output\*\Admins_ByRole.csv" | Should -Be $true
        Test-Path ".\test-output\*\Potential_BreakGlass.csv" | Should -Be $true
    }
}
```

### 5.5 Performance Considerations

#### **Optimization Strategies**
1. **Parallel Processing**: Use `ForEach-Object -Parallel` for independent operations
2. **Caching**: Cache frequently accessed data (roles, policies)
3. **Selective Properties**: Only request needed properties from Graph API
4. **Batch Operations**: Group related API calls together

#### **Memory Management**
```powershell
# Process large datasets in chunks
$chunkSize = 1000
for ($i = 0; $i -lt $largeArray.Count; $i += $chunkSize) {
    $chunk = $largeArray[$i..($i + $chunkSize - 1)]
    # Process chunk
    $chunk = $null  # Clear from memory
    [System.GC]::Collect()  # Force garbage collection
}
```

### 5.6 Error Recovery

#### **Retry Logic**
```powershell
function Invoke-GraphApiWithRetry {
    param(
        [scriptblock]$ApiCall,
        [int]$MaxRetries = 3,
        [int]$DelaySeconds = 2
    )
    
    $attempt = 0
    do {
        try {
            return & $ApiCall
        } catch {
            $attempt++
            if ($attempt -ge $MaxRetries) {
                throw
            }
            Write-Log WARN "API call failed, retrying in $DelaySeconds seconds (attempt $attempt/$MaxRetries)"
            Start-Sleep -Seconds $DelaySeconds
        }
    } while ($attempt -lt $MaxRetries)
}
```

### 5.7 Monitoring and Logging

#### **Enhanced Logging**
```powershell
function Write-PerformanceLog {
    param(
        [string]$Operation,
        [datetime]$StartTime,
        [int]$ItemCount
    )
    
    $duration = (Get-Date) - $StartTime
    $rate = if ($duration.TotalSeconds -gt 0) { $ItemCount / $duration.TotalSeconds } else { 0 }
    
    Write-Log INFO "$Operation completed: $ItemCount items in $($duration.TotalSeconds.ToString('F2'))s ($rate.ToString('F2') items/sec)"
}
```

---

## Implementation Timeline

### Week 1: Foundation Scripts
- [ ] Implement `02_Audit-PrivilegedUsers.ps1`
- [ ] Implement `04_Audit-ConditionalAccess.ps1`
- [ ] Implement `05_Audit-AdminAuthMethods.ps1`
- [ ] Test with mock data

### Week 2: Service Account Analysis
- [ ] Implement `03_Audit-ServicePrincipals.ps1`
- [ ] Implement `06_Audit-ARM-WriteSignIns.ps1`
- [ ] Add performance optimizations
- [ ] Integration testing

### Week 3: Resource Analysis
- [ ] Implement `07_Audit-MI-CapableResources.ps1`
- [ ] Implement `08_Generate-Recommendations.ps1`
- [ ] Add error recovery logic
- [ ] Performance testing

### Week 4: CI/CD Integration
- [ ] Implement `09_Audit-GitHubActions.ps1`
- [ ] Implement `10_Audit-AzureDevOps.ps1`
- [ ] Implement `11_Generate-Extended-Recommendations.ps1`
- [ ] End-to-end testing

---

## Success Criteria

### Functional Requirements
- [ ] All scripts execute with real Graph API calls
- [ ] All expected CSV outputs are generated
- [ ] Output schemas match examples exactly
- [ ] Error handling works with real API failures

### Performance Requirements
- [ ] Full audit completes in < 10 minutes
- [ ] Memory usage stays under 1GB
- [ ] API rate limits are respected
- [ ] Progress reporting is accurate

### Quality Requirements
- [ ] All tests pass with real API calls
- [ ] Code coverage > 80%
- [ ] No memory leaks or performance degradation
- [ ] Comprehensive error messages

This implementation plan provides a clear roadmap for completing the final 10% of the MFA Phase 2 Audit Kit development.
