# MFA Phase 2 – Findings (Sample)

Generated: 2025-10-01T14:50:37Z

## Executive Summary
- **High risk**: 2 privileged users without MFA (password-based auth)
- **Service principals**: 2 with password credentials (one expired), 1 OIDC/Federated (preferred)
- **Conditional Access**: MFA enforced for admins; exclusions include BreakGlass_* (OK) and Service Principals (review)
- **Non-interactive writes**: 3 recent events likely to **break** under Phase 2 (user/PAT-based)
- **Managed identity**: Supported on 5 key resources; 3 **not configured**

## Top Actions
1. Migrate Azure DevOps and legacy scripts to **Managed Identities** or **OIDC** workload identities (3 targets).
2. Enforce **FIDO2/passkeys** for all Global Admins; remove password-only methods (1 affected admin).
3. Scope CA policies precisely; re-check **Service Principals** exclusions (2 policies with risky exclusions).
4. Rotate/remove **password credentials** on Terraform/legacy service principals (1 password-based connection identified).
5. Re-test critical pipelines in a **Phase 2 simulated** tenant.

## Notable Items
- Bob Smith (Global Admin) lacks MFA → enable passkey / FIDO2.
- AzDO Service Connection uses password credential → move to federation.
- Report-only CA policy for compliant devices → promote to **On** once validated.

## Artifacts
- [examples/Admins_ByRole.csv](../examples/Admins_ByRole.csv)
- [examples/Potential_BreakGlass.csv](../examples/Potential_BreakGlass.csv)
- [examples/ServicePrincipals_Credentials.csv](../examples/ServicePrincipals_Credentials.csv)
- [examples/ConditionalAccess_Policies.csv](../examples/ConditionalAccess_Policies.csv)
- [examples/Admin_AuthMethods.csv](../examples/Admin_AuthMethods.csv)
- [examples/ARM_SignIns_NonInteractive.csv](../examples/ARM_SignIns_NonInteractive.csv)
- [examples/ManagedIdentity_Capable_Resources.csv](../examples/ManagedIdentity_Capable_Resources.csv)

> This sample is provided for packaging/testing. Replace with real outputs from `scripts/Run-Audit.ps1`.
