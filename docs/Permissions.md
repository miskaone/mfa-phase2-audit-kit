# Permissions -- MFA Phase 2 Audit & Recommendations Kit

This document explains the **Microsoft Graph API scopes** and optional
tokens required to run the MFA Phase 2 audit toolkit, along with **admin
consent steps**.

------------------------------------------------------------------------

## 1. Required Microsoft Graph Scopes

The toolkit requires read-only access to tenant identity, policies, and
sign-in logs:

-   `Directory.Read.All` -- read directory data\
-   `AuditLog.Read.All` -- read sign-in and audit logs\
-   `Policy.Read.All` -- read all policies\
-   `Policy.Read.ConditionalAccess` -- read Conditional Access policies\
-   `UserAuthenticationMethod.Read.All` -- read authentication methods
    (e.g., FIDO2/passkeys)\
-   `RoleManagement.Read.Directory` -- read directory role assignments

------------------------------------------------------------------------

## 2. Optional Scopes (CI/CD)

If you want to include **GitHub Actions** or **Azure DevOps** audits:

-   **GitHub Personal Access Token (PAT)**
    -   Required scopes: `repo`, `read:org`\

    -   Set as environment variable:

```powershell
$env:GITHUB_TOKEN = '<gh_token>'
```
-   **Azure DevOps Personal Access Token (PAT)**
    -   Required scopes: Service Connections (read), Pipelines (read),
        Variable Groups (read)\

    -   Set as environment variables:

```powershell
$env:AZDO_ORG_URL = 'https://dev.azure.com/<org>'
$env:AZDO_PAT     = '<azdo_pat>'
```

------------------------------------------------------------------------

## 3. Granting Consent (Admin Steps)

1.  Sign in to **Azure Portal** as a **Global Admin**.\
2.  Navigate to: **Azure Active Directory → App registrations → MFA
    Phase 2 Audit App** (or equivalent).\
3.  Under **API Permissions**, click **Add a permission → Microsoft
    Graph → Application permissions**.\
4.  Add all required scopes from section 1.\
5.  Click **Grant admin consent** for the tenant.\
6.  Verify in the portal that the status column shows **Granted for
    `<tenant>`{=html}**.

------------------------------------------------------------------------

## 4. Verification

Run the prerequisites script and ensure no missing-scope errors:

```powershell
.\src\core\01_Prereqs.ps1
```

If consent is incomplete, Graph API calls (audit log queries, CA policy
reviews, role enumerations) will fail with a **403 Unauthorized** or
**Insufficient privileges** error.

------------------------------------------------------------------------

## 5. Security Notes

-   The toolkit is **read-only** and does not mutate tenant resources.\
-   Tokens are only pulled from environment variables (never written to
    disk).\
-   Prefer **workload identities** over long-lived PATs for GitHub/Azure
    DevOps pipelines.

------------------------------------------------------------------------

✅ Once these scopes are granted, the audit kit can fully enumerate
privileged roles, CA policies, admin auth methods, and sign-in patterns
under MFA enforcement.
