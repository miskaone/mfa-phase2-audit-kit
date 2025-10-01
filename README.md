# Microsoft MFA Phase 2 – Audit & Recommendations Kit

[![PowerShell Lint](https://github.com/flowevolve/mfa-phase2-audit-kit/workflows/PowerShell%20Lint%20(PSScriptAnalyzer)/badge.svg)](https://github.com/flowevolve/mfa-phase2-audit-kit/actions/workflows/ps-lint.yml)
[![Markdown Lint](https://github.com/flowevolve/mfa-phase2-audit-kit/workflows/Markdown%20Lint/badge.svg)](https://github.com/flowevolve/mfa-phase2-audit-kit/actions/workflows/markdownlint.yml)
[![YAML Lint](https://github.com/flowevolve/mfa-phase2-audit-kit/workflows/YAML%20Lint/badge.svg)](https://github.com/flowevolve/mfa-phase2-audit-kit/actions/workflows/yamllint.yml)
[![CodeQL](https://github.com/flowevolve/mfa-phase2-audit-kit/workflows/CodeQL%20(PowerShell)/badge.svg)](https://github.com/flowevolve/mfa-phase2-audit-kit/actions/workflows/codeql.yml)
[![Gitleaks](https://github.com/flowevolve/mfa-phase2-audit-kit/workflows/Gitleaks%20(Secrets%20Scan)/badge.svg)](https://github.com/flowevolve/mfa-phase2-audit-kit/actions/workflows/gitleaks.yml)

A PowerShell toolkit to discover Phase 2 MFA risks in Azure/Entra and produce actionable recommendations. Optional modules assess GitHub Actions and Azure DevOps to replace long-lived PATs with OIDC/workload identities.

---

## 0. Executive Summary

This executive summary highlights the critical dates and top actions organizations must take to prepare for Microsoft's Phase 2 Mandatory Multi-Factor Authentication (MFA) enforcement.

### Key Dates
- October 1, 2025 – Azure Resource Manager Phase 2 rollout begins (MFA required for create/update/delete).
- August 30, 2025 – Partner Center portal MFA enforcement.
- September 30, 2025 – Partner Center API becomes MFA-ready.
- April 1, 2026 – Partner Center API requires MFA.
- July 1, 2026 – Final postponement deadline for Azure Resource Manager MFA Phase 2.

### Top 5 Immediate Actions
1. Audit all admin and service accounts; eliminate password-based automation.
2. Enable Conditional Access or Security Defaults for MFA across the tenant.
3. Transition automation to Managed Identities or Service Principals.
4. Distribute and enforce FIDO2 keys/passkeys for administrators.
5. Validate key scripts, pipelines, and Partner Center API integrations under MFA enforcement.

---

## 1. Features

- Privileged role inventory & potential break-glass detection
- Conditional Access review (MFA requirement, risky exclusions)
- Service principal credential posture (password vs. cert)
- Admin auth methods (FIDO2/passkeys coverage)
- Non-interactive ARM sign-ins likely to break under MFA
- Managed Identity capability vs. usage across common resources
- CI/CD add-ons: GitHub workflow PAT patterns, OIDC readiness; AzDO service connections & variable groups

---

## 2. Requirements

- PowerShell 7+
- Modules: `Microsoft.Graph`, `Az.Accounts`, `Az.Resources` (auto-installed by `01_Prereqs.ps1`)
- Azure Reader (tenant/sub as appropriate)

---

## 3. Permissions (Graph scopes)

Required:
- `Directory.Read.All`
- `AuditLog.Read.All`
- `Policy.Read.All`
- `Policy.Read.ConditionalAccess`
- `UserAuthenticationMethod.Read.All`
- `RoleManagement.Read.Directory`

Optional:
- GitHub token: `repo`, `read:org` → set `GITHUB_TOKEN`
- Azure DevOps PAT: read access to Service Connections, Pipelines, Variable Groups → set `AZDO_PAT`, `AZDO_ORG_URL`

---

## 4. Quick Start

### Option 1: One-Click Bootstrap (Recommended)
```powershell
Set-ExecutionPolicy -Scope Process Bypass -Force
git clone https://github.com/<org>/mfa-phase2-audit-kit.git
cd mfa-phase2-audit-kit

# Install modules and run full audit
.\scripts\bootstrap.ps1

# Or with CI/CD integration
.\scripts\bootstrap.ps1 -IncludeGitHub -IncludeAzDO
```

### Option 2: Manual Setup
```powershell
Set-ExecutionPolicy -Scope Process Bypass -Force
git clone https://github.com/<org>/mfa-phase2-audit-kit.git
cd mfa-phase2-audit-kit

# Optional CI/CD inputs
$env:GITHUB_TOKEN = '<gh_token>'      # if auditing GitHub
$env:AZDO_ORG_URL = 'https://dev.azure.com/<org>'
$env:AZDO_PAT     = '<azdo_pat>'      # if auditing AzDO

.\scripts\Run-Audit.ps1 -OutputRoot .\output -IncludeGitHub -GitHubOrg <org> -IncludeAzDO
```

### Option 3: Individual Scripts
```powershell
# Run specific audit modules
.\src\core\02_Audit-PrivilegedUsers.ps1
.\src\core\04_Audit-ConditionalAccess.ps1
.\src\core\05_Audit-AdminAuthMethods.ps1
```

---

## 5. Output

Generated under `./output/<timestamp>/`:

- `Admins_ByRole.csv`, `Potential_BreakGlass.csv`
- `ServicePrincipals_Credentials.csv`
- `ConditionalAccess_Policies.csv`
- `Admin_AuthMethods.csv`
- `ARM_SignIns_NonInteractive.csv`
- `ManagedIdentity_Capable_Resources.csv`
- `MFA_Phase2_Findings.md` (summary + top actions; appends CI/CD findings if enabled)

---

## 6. Repo Structure

```
/src/core
  01_Prereqs.ps1
  02_Audit-PrivilegedUsers.ps1
  03_Audit-ServicePrincipals.ps1
  04_Audit-ConditionalAccess.ps1
  05_Audit-AdminAuthMethods.ps1
  06_Audit-ARM-WriteSignIns.ps1
  07_Audit-MI-CapableResources.ps1
  08_Generate-Recommendations.ps1
/src/ci_cd
  09_Audit-GitHubActions.ps1
  10_Audit-AzureDevOps.ps1
  11_Generate-Extended-Recommendations.ps1
/scripts
  Run-Audit.ps1
/docs  (quickstart, permissions, troubleshooting)
/examples (sample outputs, OIDC YAML)
```

---

## 7. CI/CD (repo)

- **CI**: PowerShell lint (`PSScriptAnalyzer`), `markdownlint`, `yamllint`
- **Security**: CodeQL (PowerShell), gitleaks (secrets)
- **Release**: on tag `v*`, package `/src`, `/scripts`, `/docs` as ZIP and attach to GitHub Release

---

## 8. Safety Notes

- Read-only audits; no resource mutation
- Tokens only consumed from environment variables; not stored
- Prefer workload identities over long-lived secrets

---

## 9. Troubleshooting

- Module install failures → run PowerShell as admin; retry `01_Prereqs.ps1`
- Graph scope errors → verify consent for listed scopes
- Empty sign-ins → increase `-DaysBack` in `06_Audit-ARM-WriteSignIns.ps1`
- CI/CD audits require tokens; ensure `GITHUB_TOKEN` / `AZDO_PAT` are set

---

## 10. License & Credits

- **License**: MIT
- Built by Flow Evolve to help teams prepare for Microsoft’s MFA Phase 2.

---

## 11. Readiness Checklist

### 1. Key Deadlines
- Azure Resource Manager (Phase 2):
  - October 1, 2025: Safe-deployment rollout begins (MFA required for create/update/delete).
  - Up to July 1, 2026: Postponement window available.
- Partner Center:
  - August 30, 2025: MFA required for portal sign-in.
  - September 30, 2025: API "MFA-ready".
  - April 1, 2026: MFA mandatory for Partner Center APIs.

### 2. Tenant & Identity Prep
- Audit all user accounts with Azure roles (Contributor, Owner, Global Admin).
- Audit service accounts tied to username+password.
- Enable Security Defaults or Conditional Access MFA policies.
- Ensure break-glass accounts exist (tested with hardware keys).
- Enroll admins in FIDO2 keys or passkeys.

### 3. Automation & Service Accounts
- Inventory all scripts, pipelines, IaC, CLI/PowerShell jobs calling Azure APIs.
- Replace credential-based service accounts with Managed Identities or Service Principals.
- Validate automation runs without interactive MFA prompts.

### 4. Tooling & Client Versions
- Azure CLI ≥ 2.76.
- Azure PowerShell ≥ 14.3.
- Update SDKs to support MFA token refresh.
- Test Terraform/Bicep/ARM pipelines with workload identities.

### 5. Governance & Communications
- Create internal policy memo on MFA enforcement impact and dates.
- Train admins and developers on new auth methods.
- Update runbooks for automation failures (expired credentials → reconfigure identities).
- Define exception handling process (postponement requests, migration timelines).

### 6. Validation / Dry Runs
- Run test tenant with Phase 2 enforcement to validate automation.
- Monitor dashboards for MFA-related failures.
- Track 100% migration of service accounts.

### 7. Partner Center Specific
- Update Partner Center API integrations for OAuth + MFA support.
- Validate token refresh cycles in automation.
- Communicate changes to third-party integrators or CSP resellers.