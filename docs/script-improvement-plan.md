# Script Improvement Plan - MFA Phase 2 Audit Kit

## Overview
This plan addresses all identified issues in the PowerShell scripts to ensure completeness, accuracy, and consistency across the audit toolkit.

## Priority Levels
- **P0**: Critical - Blocks functionality
- **P1**: High - Major functionality gaps
- **P2**: Medium - Consistency and quality improvements
- **P3**: Low - Nice-to-have enhancements

---

## Phase 1: Critical Fixes (P0)

### 1.1 Fix Prerequisites Script
**Issue**: `01_Prereqs.ps1` not using Common.psm1 pattern
**Impact**: Inconsistent module management
**Solution**:
```powershell
# Replace current implementation with:
Import-Module "$PSScriptRoot\..\..\scripts\Common.psm1" -Force
Ensure-Modules -Names @("Microsoft.Graph", "Az.Accounts", "Az.Resources")
```

### 1.2 Fix Recommendations Output Handling
**Issue**: `08_Generate-Recommendations.ps1` tries to export markdown as CSV
**Impact**: Broken output generation
**Solution**:
- Remove CSV export logic
- Write markdown directly to file using `Out-File`
- Update function to return markdown content properly

### 1.3 Add Environment Variable Validation
**Issue**: CI/CD scripts don't validate required environment variables
**Impact**: Silent failures when tokens missing
**Solution**:
```powershell
# Add to 09_Audit-GitHubActions.ps1
if (-not $env:GITHUB_TOKEN) {
    throw "GITHUB_TOKEN environment variable is required"
}

# Add to 10_Audit-AzureDevOps.ps1
if (-not $env:AZDO_PAT -or -not $env:AZDO_ORG_URL) {
    throw "AZDO_PAT and AZDO_ORG_URL environment variables are required"
}
```

---

## Phase 2: Major Functionality Gaps (P1)

### 2.1 Add Break-Glass Detection
**Issue**: `02_Audit-PrivilegedUsers.ps1` missing break-glass detection
**Impact**: Missing critical security analysis
**Solution**:
- Add `Test-BreakGlassAccount` function
- Generate `Potential_BreakGlass.csv` output
- Detect patterns: excluded from CA, high-privilege without MFA, emergency accounts

### 2.2 Add Azure Connection for MI Resources
**Issue**: `07_Audit-MI-CapableResources.ps1` needs Azure connection
**Impact**: Cannot enumerate Azure resources
**Solution**:
```powershell
# Add to Common.psm1
function Connect-AzIfNeeded {
    try {
        if (-not (Get-AzContext)) {
            Write-Log INFO "Connecting to Azure"
            Connect-AzAccount -NoWelcome
        }
    } catch {
        throw "Failed to connect to Azure: $($_.Exception.Message)"
    }
}
```

### 2.3 Implement Core Function Logic
**Issue**: All functions are TODO stubs
**Impact**: Scripts produce no meaningful output
**Solution**: Implement key functions with proper Graph API calls

---

## Phase 3: Consistency Improvements (P2)

### 3.1 Align Graph Scopes
**Issue**: Some scripts request unnecessary scopes
**Impact**: Over-privileged access requests
**Solution**:
- `07_Audit-MI-CapableResources.ps1`: Remove `Directory.Read.All`, add Azure connection
- `08_Generate-Recommendations.ps1`: Remove `Directory.Read.All` (no Graph calls needed)
- `09_Audit-GitHubActions.ps1`: Remove all Graph scopes (uses GitHub API)

### 3.2 Fix Parameter Usage
**Issue**: `DaysBack` parameter defined but not used
**Impact**: Confusing API
**Solution**:
- Remove `DaysBack` from scripts where not relevant (CA policies, MI resources)
- Implement `DaysBack` usage in sign-in log queries
- Add parameter validation

### 3.3 Standardize Output Schemas
**Issue**: Output schemas don't match examples
**Impact**: Inconsistent data structure
**Solution**:
- Update all scripts to match example CSV schemas
- Add required columns (IDs, timestamps, boolean flags)
- Ensure consistent data types

---

## Phase 4: Quality Enhancements (P3)

### 4.1 Add Comprehensive Function Documentation
**Issue**: Function parameters lack proper documentation
**Impact**: Poor maintainability
**Solution**:
```powershell
function Get-PrivilegedUsers {
    <#
    .SYNOPSIS
    Retrieves users with privileged directory roles
    
    .DESCRIPTION
    Enumerates all directory roles and their members, returning user details
    
    .OUTPUTS
    PSCustomObject[] - Array of user objects with role information
    #>
    param()
    # Implementation
}
```

### 4.2 Add Input Validation
**Issue**: No validation for script parameters
**Impact**: Runtime errors with invalid inputs
**Solution**:
```powershell
param(
    [Parameter(Mandatory=$true)]
    [ValidateScript({Test-Path $_ -PathType Container})]
    [string]$OutputRoot
)
```

### 4.3 Add Progress Reporting
**Issue**: No progress indication for long-running operations
**Impact**: Poor user experience
**Solution**:
```powershell
$total = $items.Count
$current = 0
foreach ($item in $items) {
    $current++
    Write-Progress -Activity "Processing items" -Status "Item $current of $total" -PercentComplete (($current / $total) * 100)
}
```

---

## Implementation Timeline

### Week 1: Critical Fixes
- [ ] Fix prerequisites script
- [ ] Fix recommendations output handling
- [ ] Add environment variable validation
- [ ] Test basic script execution

### Week 2: Core Functionality
- [ ] Implement break-glass detection
- [ ] Add Azure connection for MI resources
- [ ] Implement core Graph API calls
- [ ] Generate meaningful test outputs

### Week 3: Consistency & Quality
- [ ] Align Graph scopes
- [ ] Fix parameter usage
- [ ] Standardize output schemas
- [ ] Add comprehensive documentation

### Week 4: Testing & Validation
- [ ] Unit tests for all functions
- [ ] Integration tests with mock data
- [ ] End-to-end testing
- [ ] Performance optimization

---

## Testing Strategy

### Unit Tests
```powershell
# Example test structure
Describe "Get-PrivilegedUsers" {
    It "Should return users with roles" {
        Mock Get-MgRoleManagementDirectoryRoleAssignment { return @($mockRole) }
        Mock Get-MgUser { return @($mockUser) }
        
        $result = Get-PrivilegedUsers
        $result | Should -Not -BeNullOrEmpty
    }
}
```

### Integration Tests
- Test with mock Graph API responses
- Validate CSV output schemas
- Test error handling scenarios

### End-to-End Tests
- Run full audit with test tenant
- Validate all outputs are generated
- Test CI/CD integration

---

## Success Criteria

### Functional Requirements
- [ ] All scripts execute without errors
- [ ] All required outputs are generated
- [ ] Output schemas match examples
- [ ] Error handling works correctly

### Quality Requirements
- [ ] All functions have proper documentation
- [ ] Code follows consistent patterns
- [ ] Performance is acceptable (< 5 minutes for full audit)
- [ ] All tests pass

### Security Requirements
- [ ] Minimal required permissions requested
- [ ] No hardcoded secrets
- [ ] Proper error handling for auth failures
- [ ] Environment variables properly validated

---

## Risk Mitigation

### High Risk
- **Graph API changes**: Use versioned endpoints, add error handling
- **Permission issues**: Test with minimal required scopes
- **Performance**: Add progress reporting, optimize queries

### Medium Risk
- **Output format changes**: Use examples as golden files
- **Module compatibility**: Pin specific versions
- **Cross-platform issues**: Test on Windows/Linux

### Low Risk
- **Documentation gaps**: Add as part of implementation
- **Code style**: Use PSScriptAnalyzer rules
- **Test coverage**: Aim for 80%+ coverage

---

## Monitoring & Maintenance

### Continuous Integration
- Run PSScriptAnalyzer on all changes
- Validate output schemas in CI
- Test with mock data on every commit

### Regular Updates
- Review Graph API changes quarterly
- Update module versions monthly
- Refresh test data annually

### Documentation
- Keep README updated with new features
- Maintain troubleshooting guide
- Document any breaking changes
