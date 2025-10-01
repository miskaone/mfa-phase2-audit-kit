# Quick Start -- MFA Phase 2 Audit & Recommendations Kit

This guide helps you run your **first audit** of Azure/Entra MFA Phase 2
risks with minimal setup.

------------------------------------------------------------------------

## 1. Prerequisites

-   **PowerShell 7+**\
-   Internet access to install required modules\
-   Azure **Reader** permissions at the tenant/subscription level\
-   Optional: tokens for CI/CD audits (GitHub, Azure DevOps)

------------------------------------------------------------------------

## 2. Clone the Repo

``` powershell
git clone https://github.com/<org>/mfa-phase2-audit-kit.git
cd mfa-phase2-audit-kit
```

------------------------------------------------------------------------

## 3. Install Modules

Run prerequisites once:

``` powershell
Set-ExecutionPolicy -Scope Process Bypass -Force
.\src\core_Prereqs.ps1
```

This installs: - Microsoft.Graph\
- Az.Accounts\
- Az.Resources

------------------------------------------------------------------------

## 4. Run a Basic Audit

``` powershell
.\scripts\Run-Audit.ps1 -OutputRoot .\output
```

------------------------------------------------------------------------

## 5. Run with CI/CD Inputs (Optional)

Set environment variables if you want to include GitHub or Azure DevOps
audits:

``` powershell
# GitHub
$env:GITHUB_TOKEN = '<gh_token>'
# Azure DevOps
$env:AZDO_ORG_URL = 'https://dev.azure.com/<org>'
$env:AZDO_PAT     = '<azdo_pat>'
```

Then:

``` powershell
.\scripts\Run-Audit.ps1 -OutputRoot .\output -IncludeGitHub -GitHubOrg <org> -IncludeAzDO
```

------------------------------------------------------------------------

## 6. Check the Output

All results are stored under:

`.\output\<timestamp>`

Look for: - `MFA_Phase2_Findings.md` -- summary + top actions\
- CSVs for admins, service principals, policies, sign-ins, etc.

------------------------------------------------------------------------

## 7. Next Steps

-   Review findings and prioritize **removing password-based
    automation**\
-   Enable **Conditional Access MFA policies**\
-   Transition automation to **Managed Identities/Service Principals**\
-   Enforce **FIDO2 keys/passkeys** for admins\
-   Test key scripts and pipelines under MFA

------------------------------------------------------------------------

✅ You're now ready to assess your environment for Microsoft's MFA Phase
2 rollout.
