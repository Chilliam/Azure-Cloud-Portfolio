# Project 5: Automation — README

## Overview

This project automates two repetitive Azure Admin tasks: bulk user provisioning into Entra ID, and scheduled VM start/stop through Azure Automation. It builds directly on the environment from Projects 1, 3, and 4 — the users get added to the groups created in Project 2, and the VM automation targets the VMs and resource group from Project 3.

---

## Objectives Completed

- **Bulk user provisioning script** (`New-BulkUsers-AzCLI.ps1`) that reads a CSV of planned users, checks for existing accounts before creating (idempotent — safe to re-run), creates new users with randomly generated passwords, adds each to the correct Entra ID group, and writes a timestamped results log for every run
- **Dry-run support** (`-WhatIf` flag) that previews exactly what the script would do without making any real changes, mirroring the same dry-run discipline used with `terraform plan` and `az deployment group what-if` in earlier projects
- **Azure Automation Account** (`aa-project5-dev`) provisioned with a **system-assigned managed identity** — no stored credentials anywhere in the automation pipeline
- **Least-privilege role assignment** — the managed identity was granted `Virtual Machine Contributor`, scoped to just the project's resource group, not the subscription
- **Two PowerShell runbooks** (`Stop-DevVMs`, `Start-DevVMs`) that start/stop every VM in the resource group, tested manually before being trusted to run unattended
- **Two linked schedules** — VMs stop nightly at 11 PM and start weekday mornings at 7 AM, cutting compute costs outside working hours
- **Full reconciliation into Terraform** — every resource from this project (Automation Account, both runbooks, both schedule links) was brought under Terraform management via `terraform import` and the newer `generate-config-out` workflow, eliminating the drift this project initially introduced

---

## Challenges We Ran Into (and How We Resolved Them)

### 1. PowerShell execution policy blocked every script
**Problem:** Windows' default execution policy (`Restricted`) blocked even the profile script from loading, before any real work could start.
**Fix:** `Set-ExecutionPolicy RemoteSigned -Scope CurrentUser` — allows locally-written scripts to run while still requiring downloaded scripts to be signed.

### 2. Copy-pasted script produced cascading parser errors
**Problem:** Pasting a script from chat into an editor silently introduced smart/curly quotes and non-ASCII characters (arrows, em-dashes), which PowerShell's parser doesn't recognize as valid string delimiters — producing confusing "missing terminator" errors many lines away from the actual problem.
**Fix:** Delivered the script as a direct file download instead of copy-paste text, and standardized on plain ASCII characters throughout.

### 3. Export-Csv failed with a file-in-use error
**Problem:** The output CSV was still open in another program (Excel/Notepad) from a previous run, and Windows locks open files against being overwritten.
**Fix:** Switched the script to write a uniquely timestamped filename on every run instead of overwriting a single static file — this also gave us a full audit trail of every run rather than just the most recent one.

### 4. Microsoft Graph PowerShell SDK: partial module load failure
**Problem:** `New-MgUser` was reported as present but failed to load, eventually traced to a genuine **SDK bug**: Graph PowerShell SDK versions 2.34+ are incompatible with Windows PowerShell 5.1's .NET Framework runtime, throwing a `TypeLoadException` on `GetTokenAsync`.
**Fix attempt 1:** Installed PowerShell 7, which runs on .NET (not .NET Framework) and sidesteps the bug.
**Fix attempt 2:** Even under PowerShell 7, device-code authentication kept failing — email MFA codes were expiring on every attempt (root cause: system clock drift plus reading stale codes from a stack of previous OTP emails), and separately, the interactive browser flow threw a `response_type` malformed-request error — another SDK-level bug.
**Final resolution:** Rather than continuing to fight SDK version issues, rewrote the bulk user script to use **Azure CLI's `az ad` commands** instead of the Graph PowerShell SDK entirely. Azure CLI had been completely reliable throughout every other part of this project series, so this was a deliberate tool switch, not a workaround.

### 5. Azure CLI itself got blocked by a broken extension
**Problem:** The `ssh` CLI extension's local folder had a Windows file-permission lock, and Azure CLI tries to load metadata for every installed extension at startup — meaning **one broken extension blocked every single `az` command**, including unrelated ones like creating the Automation Account.
**Fix:** Removed the corrupted extension folder directly (`Remove-Item` after closing all terminal sessions to release the file lock; `takeown`/`icacls` as a fallback for stubborn permission locks).

### 6. Several `az automation` commands simply don't exist
**Problem:** Hit three separate, confirmed gaps in Azure CLI's `automation` extension (which is explicitly marked "experimental"):
  - `az automation account update --assign-identity` — flag doesn't exist
  - `az automation job get-output` — command doesn't exist
  - `az automation job schedule create` (linking a schedule to a runbook) — no CLI equivalent exists at all
**Fix:**
  - Enabling the managed identity: used the generic `az resource update --set identity.type=SystemAssigned` instead, since the identity property exists on any ARM resource regardless of dedicated CLI support
  - Reading job output: verified success directly via `az vm list -d` (checking actual VM power state) rather than trying to read runbook console output through CLI
  - Linking schedules to runbooks: this genuinely has no CLI path — resolved via the **Azure Portal**, which is the Microsoft-documented way to perform this specific operation

### 7. Register-AzAutomationScheduledRunbook (PowerShell alternative) failed with a null reference
**Problem:** Attempting the schedule-linking step through the `Az.Automation` PowerShell module instead of CLI threw "Object reference not set to an instance of an object" — traced to a missing `Connect-AzAccount` session (a separate login from both `az login` and `Connect-MgGraph`).
**Fix:** After authenticating, hit the same Conditional Access tenant restriction from Project 2's MFA policy, requiring `-TenantId` to be specified explicitly. Ultimately completed the schedule linking through the Portal instead, given the CLI, PowerShell module, and authentication layers had each introduced separate friction for this one specific operation.

### 8. Configuration drift after building parts of the project outside Terraform
**Problem:** Because the Automation Account, runbooks, and monitoring resources (Project 4) were built through CLI/portal rather than Terraform, they existed in Azure with zero representation in the Terraform state — a realistic drift scenario.
**Fix:** Used `az resource list` to audit the live environment against `main.tf`, then reconciled every drifted resource into Terraform using `terraform import` (manual resource blocks) and the newer `import` block + `-generate-config-out` workflow (auto-generated starting config, then manually corrected invalid/computed fields the generator got wrong — e.g., a `notification_settings.time_in_minutes` default of `0` outside the valid 15–120 range, and a `job_schedule` block incorrectly generated as a nested property instead of the separate `azurerm_automation_job_schedule` resource the provider actually expects).

### 9. Resource ID casing mismatches during import
**Problem:** `az resource show` returns resource IDs using whatever casing was passed into `--resource-type`, but Terraform's provider validates against Azure's canonical casing (e.g., `Microsoft.Insights`, not `microsoft.insights`) — causing repeated "invalid resource ID" parsing errors during import.
**Fix:** Used PowerShell regex replacements to normalize casing across all resource IDs before retrying the import.

---

## What We Learned

- **Idempotency and dry-run modes aren't just nice-to-haves** — building `-WhatIf` into the user script and relying on `terraform plan`/`what-if` before every real change caught problems before they became costly, and it's a habit worth carrying into any automation work going forward.
- **Tool version bugs are real and worth recognizing quickly.** The Graph SDK issue wasn't a knowledge gap — it was a genuine, documented compatibility bug. Recognizing that and switching tools (to Azure CLI) rather than continuing to debug an unfixable version conflict was the right call, and it's a legitimate story to tell in an interview about pragmatic troubleshooting judgment.
- **"Experimental" CLI extensions can have real, load-bearing gaps.** Three separate missing commands in `az automation` reinforced that documentation status (like Microsoft's own "experimental" label) is worth checking before assuming a CLI limitation is user error.
- **A single broken component can cascade.** The corrupted `ssh` extension blocking all of Azure CLI was a good reminder that troubleshooting sometimes means looking one layer below the command that's actually failing.
- **Managed identities are worth the setup friction.** Despite being the hardest part of this project to configure correctly, ending up with zero stored credentials anywhere in the automation pipeline is a real, defensible security posture — and a strong, specific answer to "how do you avoid hardcoding secrets in automation."
- **Drift is normal in iterative, real-world environments — the skill is reconciling it, not avoiding it entirely.** Building across five projects with a mix of Terraform, CLI, and portal work naturally created drift; the valuable skill demonstrated here is detecting it methodically and bringing it back under one accurate source of truth, which is a far more realistic scenario than a greenfield `terraform apply` on day one.

---

## Files in This Project

```
azure-automation-project/
├── users.csv                      # Input roster for bulk provisioning
├── New-BulkUsers-AzCLI.ps1         # Bulk user creation script (Azure CLI based)
├── Stop-DevVMs.ps1                 # Automation runbook — nightly VM shutdown
├── Start-DevVMs.ps1                # Automation runbook — weekday VM startup
├── bulk-user-results-*.csv         # Timestamped run logs (gitignored if containing real data)
└── README.md
```
