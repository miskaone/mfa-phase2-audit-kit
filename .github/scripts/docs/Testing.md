
# Testing Strategy (Pester + Contracts)

## Goals
- Verify each script produces **expected columns** and non-empty outputs (when mocks return data).
- Ensure Graph scopes are requested only where required.
- Keep tests fast with **mocked Graph/Az** layers.

## Setup
```powershell
Install-Module Pester -Scope CurrentUser -Force
```

## Patterns
1. **Unit tests**: mock `Get-Mg*` / `Get-Az*` calls and validate transformation functions.
2. **Contract tests**: assert CSV headers for each output file:
   - `Admins_ByRole.csv`: RoleName, UserPrincipalName, DisplayName, MFA_Enabled?, AuthMethod?
   - `ServicePrincipals_Credentials.csv`: AppId, DisplayName, CredentialType, ExpiryDate, Status
   - `ConditionalAccess_Policies.csv`: PolicyName, State, GrantControls, Exclusions, LastModified
   - `Admin_AuthMethods.csv`: UserPrincipalName, DisplayName, FIDO2, Passkey, AuthenticatorApp, Phone, PasswordlessEnabled
   - `ARM_SignIns_NonInteractive.csv`: TimeGenerated, App, Resource, Operation, Result, ClientApp, IdentityType, WillBreakUnderPhase2, Reason
   - `ManagedIdentity_Capable_Resources.csv`: SubscriptionId, ResourceGroup, ResourceType, ResourceName, Location, SupportsManagedIdentity, IdentityConfigured
3. **Smoke test**: run `scripts/Run-Audit.ps1` with a temp output folder and confirm files are created.
4. **CI hooks**: run PSScriptAnalyzer, markdownlint, yamllint, CodeQL, and gitleaks as part of PR checks.
