# Troubleshooting -- MFA Phase 2 Audit & Recommendations Kit

This document lists common issues you may encounter when running the
toolkit and how to resolve them.

------------------------------------------------------------------------

## 1. Module Installation Failures

**Symptom**: Required PowerShell modules fail to install.\
**Fix**:\
- Run PowerShell as Administrator.\
- Re-run the prerequisites script:

```powershell
.\src\core\01_Prereqs.ps1
```

------------------------------------------------------------------------

## 2. Graph Scope Errors

**Symptom**: Audit scripts return `403 Unauthorized` or
`Insufficient privileges`.\
**Fix**:\
- Verify that all required Microsoft Graph scopes are granted with admin
consent (see Permissions.md).\
- Re-run the prerequisites script after consent.

------------------------------------------------------------------------

## 3. Empty Sign-In Results

**Symptom**: No sign-in events returned when running ARM sign-in
audits.\
**Fix**:\
- Increase the number of days queried:

```powershell
.\src\core\06_Audit-ARM-WriteSignIns.ps1 -DaysBack 30
```

Default may be too short to capture relevant events.

------------------------------------------------------------------------

## 4. CI/CD Audit Failures (GitHub / AzDO)

**Symptom**: GitHub or Azure DevOps audit scripts fail with missing or
invalid token errors.\
**Fix**:\
- Ensure tokens are set as environment variables:

```powershell
$env:GITHUB_TOKEN = '<gh_pat>'
$env:AZDO_ORG_URL = 'https://dev.azure.com/<org>'
$env:AZDO_PAT     = '<azdo_pat>'
```

- Verify the tokens include the required scopes (see Permissions.md).
- Tokens are only consumed in-session and never stored to disk.

------------------------------------------------------------------------

## 5. General Debug Tips

-   Always check `output/<timestamp>/MFA_Phase2_Findings.md` for error
    context.\

-   Run PowerShell with `-Verbose` flag to capture additional diagnostic
    information.\

-   Use `Get-Module` and `Get-InstalledModule` to confirm dependencies
    are loaded.\

-   If repeated failures occur, clear module caches:

```powershell
Remove-Module Microsoft.Graph -Force
Uninstall-Module Microsoft.Graph -AllVersions -Force
Install-Module Microsoft.Graph -Scope CurrentUser
```

------------------------------------------------------------------------

✅ Following these steps should resolve most setup and runtime issues
when running the MFA Phase 2 audit toolkit.
