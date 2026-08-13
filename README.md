# Project 2: Identity & Governance — README

## Overview

This project built out an Entra ID environment with test users and groups, a custom least-privilege RBAC role, Conditional Access with MFA, and Azure Policy governance rules — directly mapping to the AZ-104 "Identities & Governance" domain.

---

## Objectives Completed

- **Test users and groups** — four users split across an admins group and a readers group, using group-based role assignment rather than per-user assignment
- **Custom RBAC role** ("VM Operator") scoped to only start/stop/restart permissions, with no create or delete rights — built and verified via both the Portal UI and raw JSON
- **Verified least privilege in practice** — signed in as a test user directly and confirmed she could operate a VM but was blocked from deleting or creating one, rather than just trusting the role definition on paper
- **Conditional Access policy** requiring MFA, scoped deliberately to a test group first rather than tenant-wide
- **Azure Policy governance** — mandatory tagging enforcement and VM SKU/region restrictions, each verified with an actual before/after deployment test (denied without compliance, succeeded with it)

---

## Challenges We Ran Into (and How We Resolved Them)

### 1. Entra ID P1/P2 licensing and 365 Admin Center access issues
**Problem:** Conditional Access required a P1/P2 license not automatically active, and attempting to activate the trial via the 365 Admin Center resulted in login failures.
**Fix:** Activated the license trial directly through the Microsoft Entra admin center instead of routing through the 365 Admin Center. Separately diagnosed the login failure as a mix of possible causes — confirmed the correct Global Administrator account was being used, and ruled out the newly-created Conditional Access policy itself as an interfering factor by temporarily disabling it to test.

### 2. Custom role JSON format differed between the Portal and Azure CLI
**Problem:** JSON that worked for `az role definition create` failed in the Portal's custom role JSON tab with "Malformed JSON: 'properties' property not present."
**Fix:** Identified that the Portal expects a different, more nested structure (`{"properties": {"roleName": ..., "permissions": [...] } }` with lowercase keys) than the CLI's flatter format (`{"Name": ..., "Actions": [...] }` with capitalized keys) — two different serialization conventions for the same underlying role definition.

### 3. Creating the role definition JSON file via PowerShell repeatedly produced empty files
**Problem:** PowerShell here-string syntax (`@'...'@`) silently produced a zero-byte file, with no error shown — traced to formatting sensitivity around the closing delimiter that's easy to break during copy-paste.
**Fix:** Switched to building the JSON as a native PowerShell object (`@{ properties = @{ ... } }`) and converting it with `ConvertTo-Json`, which avoided the fragile multi-line string parsing entirely and reliably produced a valid file.

---

## What We Learned

- **A role definition isn't trustworthy until you've actually signed in as the constrained user and tried to exceed its permissions.** The custom RBAC role's real value was demonstrated by confirming the test user was blocked from deletion, not by reading the permission list back.
- **Conditional Access should always be piloted narrowly first.** Scoping the MFA policy to a specific test group before ever considering a tenant-wide rollout is standard, defensible practice — a misconfigured tenant-wide policy can lock out an entire organization, including its admins.
- **The same logical resource (a custom RBAC role) can have genuinely different required JSON shapes depending on which tool is consuming it.** Worth confirming the expected schema for the specific interface being used, rather than assuming one JSON format is universal across Portal and CLI.
- **PowerShell's here-string syntax is more fragile than it looks**, especially across copy-paste boundaries — building structured data as native objects and converting to JSON is a more reliable pattern than hand-typing multi-line JSON strings directly.

---

## Files in This Project

```
azure-project2-identity-governance/
├── README.md
├── customrole.json
└── screenshots/
    ├── users-and-groups.png
    ├── rbac-least-privilege-proof.png
    ├── conditional-access-mfa-proof.png
    └── policy-tag-enforcement-proof.png
```
