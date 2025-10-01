# PowerShell Script Placeholders - Implementation Checklist

This document tracks all placeholder scripts that need implementation for the MFA Phase 2 Audit Kit.

## Core Audit Scripts (src/core/)

### 01_Prereqs.ps1 ✅ COMPLETE
- **Status**: Fully implemented
- **Purpose**: Install required PowerShell modules
- **Dependencies**: None

### 02_Audit-PrivilegedUsers.ps1 ⚠️ PLACEHOLDER
- **Status**: Needs implementation
- **Purpose**: Audit privileged roles and potential break-glass accounts
- **Required Graph APIs**:
  - `RoleManagement.Read.Directory` - enumerate directory roles
  - `Directory.Read.All` - get role members and user details
- **Output**: `Admins_ByRole.csv`, `Potential_BreakGlass.csv`
- **Key Functions Needed**:
  - `Get-MgDirectoryRole` - list all directory roles
  - `Get-MgDirectoryRoleMember` - get role members
  - `Get-MgUser` - get user details and MFA status
  - `Test-BreakGlassAccount` - identify break-glass patterns

### 03_Audit-ServicePrincipals.ps1 ⚠️ PLACEHOLDER
- **Status**: Needs implementation
- **Purpose**: Audit service principal credential posture
- **Required Graph APIs**:
  - `Directory.Read.All` - enumerate service principals
  - `Application.Read.All` - get app credentials
- **Output**: `ServicePrincipals_Credentials.csv`
- **Key Functions Needed**:
  - `Get-MgServicePrincipal` - list all service principals
  - `Get-MgServicePrincipalPasswordCredential` - check password credentials
  - `Get-MgServicePrincipalKeyCredential` - check certificate credentials
  - `Test-PasswordCredentialRisk` - flag risky password-based SPs

### 04_Audit-ConditionalAccess.ps1 ⚠️ PLACEHOLDER
- **Status**: Needs implementation
- **Purpose**: Review Conditional Access policies for MFA enforcement
- **Required Graph APIs**:
  - `Policy.Read.ConditionalAccess` - read CA policies
  - `Policy.Read.All` - read all policies
- **Output**: `ConditionalAccess_Policies.csv`
- **Key Functions Needed**:
  - `Get-MgIdentityConditionalAccessPolicy` - list CA policies
  - `Test-MFAEnforcement` - check if MFA is required
  - `Test-RiskyExclusions` - identify dangerous exclusions
  - `Get-PolicyEffectiveness` - determine effective MFA enforcement

### 05_Audit-AdminAuthMethods.ps1 ⚠️ PLACEHOLDER
- **Status**: Needs implementation
- **Purpose**: Audit admin authentication methods (FIDO2/passkeys)
- **Required Graph APIs**:
  - `UserAuthenticationMethod.Read.All` - read auth methods
  - `Directory.Read.All` - get admin users
- **Output**: `Admin_AuthMethods.csv`
- **Key Functions Needed**:
  - `Get-MgUserAuthenticationMethod` - list user auth methods
  - `Test-FIDO2Enrollment` - check FIDO2/passkey enrollment
  - `Test-PasswordlessEnabled` - check passwordless auth status
  - `Get-EffectiveMFAStatus` - combine policy + method coverage

### 06_Audit-ARM-WriteSignIns.ps1 ⚠️ PLACEHOLDER
- **Status**: Needs implementation
- **Purpose**: Audit non-interactive ARM sign-ins with write permissions
- **Required Graph APIs**:
  - `AuditLog.Read.All` - read sign-in logs
- **Output**: `ARM_SignIns_NonInteractive.csv`
- **Key Functions Needed**:
  - `Get-MgAuditLogSignIn` - query sign-in logs
  - `Filter-WriteOperations` - identify create/update/delete operations
  - `Test-NonInteractiveAuth` - detect non-interactive authentication
  - `Predict-Phase2Breakage` - determine if operation will break under MFA

### 07_Audit-MI-CapableResources.ps1 ⚠️ PLACEHOLDER
- **Status**: Needs implementation
- **Purpose**: Inventory Managed Identity-capable resources
- **Required Azure APIs**:
  - `Az.Resources` - enumerate Azure resources
- **Output**: `ManagedIdentity_Capable_Resources.csv`
- **Key Functions Needed**:
  - `Get-AzResource` - list all resources
  - `Test-ManagedIdentitySupport` - check MI capability
  - `Get-ManagedIdentityStatus` - check current MI configuration
  - `Test-MigrationTarget` - identify resources needing MI

### 08_Generate-Recommendations.ps1 ⚠️ PLACEHOLDER
- **Status**: Needs implementation
- **Purpose**: Generate MFA Phase 2 recommendations summary
- **Dependencies**: All previous audit outputs
- **Output**: `MFA_Phase2_Findings.md`
- **Key Functions Needed**:
  - `Import-AuditResults` - load all CSV outputs
  - `Analyze-Findings` - identify high-risk items
  - `Generate-TopActions` - create prioritized action list
  - `Export-MarkdownReport` - generate findings document

## CI/CD Audit Scripts (src/ci_cd/)

### 09_Audit-GitHubActions.ps1 ⚠️ PLACEHOLDER
- **Status**: Needs implementation
- **Purpose**: Audit GitHub Actions for PAT usage and OIDC readiness
- **Dependencies**: `$env:GITHUB_TOKEN` with `repo`, `read:org` scopes
- **Output**: `GitHubActions_Audit.csv`
- **Key Functions Needed**:
  - `Get-GitHubWorkflows` - list all workflows
  - `Test-PATUsage` - detect long-lived PAT usage
  - `Test-OIDCReadiness` - check OIDC configuration
  - `Get-SecretUsage` - identify secret dependencies

### 10_Audit-AzureDevOps.ps1 ⚠️ PLACEHOLDER
- **Status**: Needs implementation
- **Purpose**: Audit Azure DevOps service connections and variable groups
- **Dependencies**: `$env:AZDO_PAT`, `$env:AZDO_ORG_URL`
- **Output**: `AzureDevOps_Audit.csv`
- **Key Functions Needed**:
  - `Get-AzDoServiceConnections` - list service connections
  - `Get-AzDoVariableGroups` - list variable groups
  - `Test-PATBasedConnections` - identify PAT-based connections
  - `Test-WorkloadIdentityReadiness` - check OIDC readiness

### 11_Generate-Extended-Recommendations.ps1 ⚠️ PLACEHOLDER
- **Status**: Needs implementation
- **Purpose**: Append CI/CD findings to main recommendations
- **Dependencies**: GitHub/AzDO audit outputs
- **Output**: Updates `MFA_Phase2_Findings.md`
- **Key Functions Needed**:
  - `Import-CICDFindings` - load CI/CD audit results
  - `Merge-Recommendations` - combine with core findings
  - `Update-MarkdownReport` - append CI/CD section

## Orchestration Script (scripts/)

### Run-Audit.ps1 ✅ COMPLETE
- **Status**: Fully implemented
- **Purpose**: Orchestrate the full audit process
- **Dependencies**: All core and CI/CD scripts

## Implementation Priority

### Phase 1 (Core Functionality)
1. **02_Audit-PrivilegedUsers.ps1** - Foundation for admin analysis
2. **04_Audit-ConditionalAccess.ps1** - Critical for MFA policy review
3. **08_Generate-Recommendations.ps1** - Essential for output generation

### Phase 2 (Service Account Analysis)
4. **03_Audit-ServicePrincipals.ps1** - Service principal credential audit
5. **05_Audit-AdminAuthMethods.ps1** - Admin authentication method audit
6. **06_Audit-ARM-WriteSignIns.ps1** - Sign-in log analysis

### Phase 3 (Resource Analysis)
7. **07_Audit-MI-CapableResources.ps1** - Managed Identity inventory

### Phase 4 (CI/CD Integration)
8. **09_Audit-GitHubActions.ps1** - GitHub Actions audit
9. **10_Audit-AzureDevOps.ps1** - Azure DevOps audit
10. **11_Generate-Extended-Recommendations.ps1** - CI/CD recommendations

## Testing Strategy

### Unit Testing
- Each script should include `-WhatIf` parameter support
- Mock Graph API calls for testing without live data
- Validate CSV output schemas match examples

### Integration Testing
- Test with minimal Graph permissions
- Validate error handling for missing scopes
- Test CI/CD scripts with mock tokens

### End-to-End Testing
- Run full audit on test tenant
- Validate all outputs are generated
- Test recommendations generation

## Common Patterns

### Error Handling
```powershell
try {
    $result = Get-MgUser -UserId $userId -ErrorAction Stop
} catch {
    Write-Warning "Failed to get user $userId`: $($_.Exception.Message)"
    continue
}
```

### Progress Reporting
```powershell
$total = $items.Count
$current = 0
foreach ($item in $items) {
    $current++
    Write-Progress -Activity "Processing items" -Status "Item $current of $total" -PercentComplete (($current / $total) * 100)
    # Process item
}
```

### CSV Export
```powershell
$results | Export-Csv -Path $outputPath -NoTypeInformation -Encoding UTF8
```

### Graph API Rate Limiting
```powershell
Start-Sleep -Milliseconds 100  # Respect rate limits
```
