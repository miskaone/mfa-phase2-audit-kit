# Microsoft MFA Phase 2 – Audit & Recommendations Kit

A PowerShell toolkit to discover Phase 2 MFA risks in Azure/Entra and produce actionable recommendations. Optional modules assess GitHub Actions and Azure DevOps to replace long-lived PATs with OIDC/workload identities.

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