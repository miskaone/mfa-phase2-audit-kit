# Testing Framework - MFA Phase 2 Audit Kit

## Overview
This directory contains the testing framework for the MFA Phase 2 Audit Kit PowerShell scripts.

## Test Structure

### Test-AuditScripts.ps1
Comprehensive test suite covering:
- Common.psm1 utility functions
- Script parameter validation
- Environment variable validation
- Output schema validation
- Error handling scenarios

## Running Tests

### Prerequisites
```powershell
Install-Module Pester -Scope CurrentUser -Force
```

### Execute All Tests
```powershell
Invoke-Pester -Path .\tests\ -OutputFile test-results.xml -OutputFormat NUnitXml
```

### Execute Specific Test
```powershell
Invoke-Pester -Path .\tests\Test-AuditScripts.ps1 -Verbose
```

## Test Categories

### Unit Tests
- Test individual functions with mocked dependencies
- Validate parameter handling and return values
- Test error conditions and edge cases

### Integration Tests
- Test script execution with mocked Graph/Azure APIs
- Validate output file generation and schemas
- Test environment variable validation

### Contract Tests
- Validate CSV output schemas match examples
- Ensure required columns are present
- Test data type consistency

## Mock Data
Tests use mocked Graph API and Azure responses to avoid requiring:
- Actual authentication tokens
- Live tenant access
- Network connectivity

## Test Data
- `test-output/` - Generated test files (auto-cleaned)
- `test-data/` - Static test data files

## Continuous Integration
Tests are designed to run in CI/CD pipelines with:
- No external dependencies
- Deterministic results
- Comprehensive coverage reporting
