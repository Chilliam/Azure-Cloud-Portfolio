# Terraform Drift Reconciliation — README

## Overview

After building infrastructure iteratively across Projects 1, 3, 4, and 5 using a mix of Terraform, Azure CLI, and the Azure Portal, the live environment in `rg-project3-tf-dev` had drifted meaningfully from the original `main.tf` — resources existed in Azure with no corresponding Terraform configuration or state tracking. This work audited that drift and brought every resource back under Terraform management, using two different import approaches depending on the tooling available.

This is a genuinely realistic scenario: very few real environments are built entirely through Terraform from day one, and reconciling drift is a common, valuable skill that a purely greenfield project doesn't demonstrate.

---

## Objectives Completed

- **Audited the live environment** against the Terraform configuration using `az resource list` and (initially) `aztfexport`, identifying every resource that existed in Azure but wasn't tracked in Terraform state
- **Imported the Log Analytics workspace** (`law-project4-dev`) manually — writing the resource block by hand, running classic `terraform import`, then iteratively correcting the configuration until `terraform plan` showed zero drift
- **Imported the remaining 8 drifted resources** (action group, metric alert, data collection rule, both auto-shutdown schedules, the Automation Account, and both runbooks) using Terraform's newer `import` block + `-generate-config-out` workflow, which auto-generates starting configuration instead of requiring every field to be hand-written
- **Corrected several auto-generated configuration errors** that the generator produced but the provider correctly rejected, rather than blindly accepting generated output
- **Reorganized the project into topic-based files** (`monitoring.tf`, `automation.tf`) rather than leaving everything in one `main.tf`, improving readability now that the project spans five distinct areas of functionality
- **Reached a fully clean state** — `terraform plan` shows zero drift across the entire environment, with every resource from Projects 1, 3, 4, and 5 represented in code

---

## Challenges We Ran Into (and How We Resolved Them)

### 1. aztfexport's full export was unusably noisy
**Problem:** Running `aztfexport resource-group` against the resource group returned over 1,000 items — far more than the actual resource count, due to child resources, role assignments, and auto-generated resources being listed individually.
**Fix:** Abandoned the full interactive export in favor of a simpler, targeted comparison: `az resource list --query "[].{Name:name, Type:type}" -o table` against the resource group, then a manual diff against the `resource` blocks already declared in `main.tf`. Much faster for identifying drift at the level that actually mattered.

### 2. aztfexport refused to write into a non-empty directory
**Problem:** Running the tool inside the existing `azure-terraform-project` folder failed, since it wouldn't write output into a directory already containing files.
**Fix:** Ran it in a separate sibling folder instead — which also turned out to be the better practice anyway, since it kept the experimental export cleanly separated from the hand-written working files.

### 3. terraform plan -generate-config-out failed with "too many command line arguments"
**Problem:** The flag was being rejected as an unrecognized positional argument.
**Root cause:** Not a version issue (confirmed on Terraform 1.15.8, well above the 1.5 minimum) — a stray space had been introduced around the `=` sign during copy-paste, splitting the flag into multiple tokens.
**Fix:** Retyped the command directly rather than pasting it.

### 4. Import block resource IDs were missing quotation marks
**Problem:** `id = /subscriptions/.../law-project4-dev` (unquoted) caused "Expected the start of an expression" — HCL requires all literal string values to be wrapped in quotes, or the parser tries to interpret them as expressions/references.
**Fix:** Used a PowerShell regex replacement (`-replace '^(\s*id\s*=\s*)(/subscriptions/\S+)$', '$1"$2"'`) to wrap every unquoted resource ID across the whole `imports.tf` file in one pass, rather than fixing each of the 8 blocks by hand.

### 5. Resource ID casing mismatches, repeated across multiple resource types
**Problem:** `az resource show` returns resource IDs using whatever casing was passed into `--resource-type` (e.g., `microsoft.insights`, `resourcegroups`), but the `azurerm` Terraform provider validates strictly against Azure's canonical casing (`Microsoft.Insights`, `resourceGroups`) — causing repeated "invalid resource ID" / "segment didn't match" errors across several different resources (action group, metric alert, both shutdown schedules).
**Fix:** Applied a batch of PowerShell regex replacements normalizing every known provider namespace and path segment across `imports.tf` in one pass, rather than fixing each casing error one at a time as `terraform plan` surfaced them individually.

### 6. Auto-generated config included an invalid computed value
**Problem:** The generated `azurerm_dev_test_global_vm_shutdown_schedule` resource included `notification_settings { time_in_minutes = 0 }`, but the provider requires this value to be between 15–120 when notifications are involved — the generator had defaulted to `0` rather than correctly omitting the block, since the real schedule never had notifications configured in the first place.
**Fix:** Removed the `notification_settings` block entirely, since it isn't required when notifications aren't in use — matching the actual real-world configuration rather than inventing a notification setup that never existed.

### 7. Auto-generated config modeled a relationship incorrectly
**Problem:** The generator wrote a `job_schedule { job_schedule_id = "..." }` block directly inside the `azurerm_automation_runbook` resource, but the provider rejected it: `job_schedule_id` is a computed, read-only value that can't be set directly.
**Fix:** Recognized this as the same "relationships are their own resource, not a nested property" pattern already seen with NSG-to-subnet and NIC-to-backend-pool associations earlier in the project. Removed the invalid nested block and added a proper standalone `azurerm_automation_job_schedule` resource instead, which is how this provider actually models a schedule-to-runbook link.

---

## What We Learned

- **Generated Terraform config is a strong starting point, not a finished product.** Every auto-generated resource in this exercise needed at least one manual correction — either an invalid default value or an incorrectly-modeled relationship. Reviewing generated output line-by-line against the provider's actual schema is a required step, not optional polish.
- **A recurring provider design pattern is worth recognizing, not re-learning each time.** The "relationships are their own resource" pattern (NSG↔subnet, NIC↔backend pool, and now runbook↔schedule) showed up three separate times across this project. Once recognized, it made the `job_schedule` error immediately diagnosable instead of a fresh mystery.
- **Azure Resource Manager's case-insensitivity doesn't extend to Terraform's provider validation.** This caused more repeated friction than almost anything else in this exercise — worth remembering for any future manual resource ID construction: always match Azure's documented canonical casing, not whatever a CLI command happened to echo back.
- **Batch fixes beat one-at-a-time fixes once a pattern is identified.** Both the missing-quotes issue and the casing issue affected multiple resources identically; recognizing that early and writing one regex replacement to fix all instances at once was significantly faster than resolving each error individually as `terraform plan` surfaced them in sequence.
- **Drift reconciliation is a real, demonstrable skill distinct from writing Terraform from scratch.** Most learning projects only ever exercise `terraform apply` against a clean slate. Auditing a live, organically-grown environment and bringing it under management — including fixing the inevitable rough edges in auto-generated config — is a closer match to what maintaining real infrastructure actually involves.

---

## Files in This Project

```
azure-terraform-project/
├── main.tf                # Core network, VMs, load balancer, NAT Gateway (Projects 1/3)
├── monitoring.tf           # Log Analytics workspace, DCR, action group, metric alert (Project 4, reconciled)
├── automation.tf           # Automation Account, runbooks, job-schedule links (Project 5, reconciled)
├── variables.tf
├── outputs.tf
├── terraform.tfvars.example
└── README.md
```

Note: `imports.tf` and `generated.tf` were used as temporary working files during the reconciliation process and removed once their contents were reviewed, corrected, and merged into the files above — they're not part of the final repo.
