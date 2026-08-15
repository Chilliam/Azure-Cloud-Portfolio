# Project 6: Backup & Disaster Recovery — README

## Overview

This project configured Azure Backup on the data-tier VM from Project 3, and — consistent with the "prove it, don't just configure it" discipline that ran through every earlier project — actually performed a full VM restore and verified the recovered data, rather than trusting a green checkmark in the portal. It closes the one clear gap in the portfolio through Project 5: nothing before this touched backup or recovery, and it directly reinforces the AZ-104 "Monitor & Maintain" domain.

---

## Objectives Completed

- **Recovery Services Vault** (`rsv-project6-dev`) created in `rg-project3-tf-dev`
- **Backup policy** (`policy-daily-vm-backup`) defined from Azure's default VM policy template, with daily scheduling and defined retention
- **Backup enabled on `vm-data-dev`**, confirmed in `Protected` state
- **On-demand backup triggered and completed** — confirmed via job status rather than assuming success
- **At least one recovery point confirmed available** for restore
- **Full VM restore performed** — restored as a new VM (not overwriting the original), disks recovered via `az backup restore restore-disks`
- **Restore verified by actually connecting to the recovered VM** and confirming data/configuration integrity — not just a "Completed" job status
- **Restored VM and disk cleaned up** after verification, to avoid ongoing cost, while leaving the vault and policy intact
- **RTO/RPO analysis written** using real observed backup and restore timings rather than estimated figures

### Verification Checklist (all confirmed)

- [x] Recovery Services Vault created
- [x] Backup policy defined with clear retention
- [x] `vm-data-dev` shows `Protected` status
- [x] At least one completed backup job (status confirmed via `az backup job list`)
- [x] A full restore performed and verified — connected to the restored VM and confirmed data integrity
- [x] RTO/RPO write-up completed with real, observed numbers
- [x] Restored VM/disk cleaned up after documentation

---

## Challenges We Ran Into (and How We Resolved Them)

### 1. Nested command substitution for the backup policy silently broke in PowerShell
**Problem:** Attempting to create the backup policy in a single command — passing `az backup policy get-default-for-vm`'s output directly into `--policy` via inline substitution — failed with `unrecognized arguments: --backup-management-type AzureIaasVM` and `argument --policy: expected one argument`.
**Fix:** Split it into two steps instead: wrote the default policy's JSON output to a file first (`> defaultpolicy.json`), verified the file actually had content, then referenced it in the `create` command with the `@filename` syntax. Avoided PowerShell's fragile handling of nested command substitution and quoting entirely.

### 2. `az backup policy get-default-for-vm` doesn't accept `--backup-management-type`
**Problem:** The same "unrecognized arguments" error persisted even after splitting into two commands, since `--backup-management-type` was mistakenly included on `get-default-for-vm` — a flag that command doesn't actually take at all (it's used by other `az backup policy` subcommands like `create`, not this one).
**Fix:** Removed the flag from `get-default-for-vm` entirely; kept it on the subsequent `create` command, where it's genuinely required.

### 3. `az backup vault show` with `--query` returned nothing
**Problem:** Piping the vault-show command through `--query provisioningState -o tsv` returned completely empty output, with no indication of whether the vault didn't exist or the query itself was wrong.
**Fix:** Diagnosed by first dropping the `--query` filter to see the raw JSON response — confirmed the vault existed, but `provisioningState` needed to be queried as a nested `properties.provisioningState` path rather than a top-level field, a modeling detail specific to Recovery Services Vaults.

### 4. Restore blocked by a prior restore operation still in progress
**Problem:** A second restore attempt failed with `UserErrorRestoreOperationInProgress`, since Azure Backup only allows one active restore per protected item at a time.
**Fix:** Checked `az backup job list` to confirm the earlier restore was still genuinely running (not stuck), and waited for it to complete rather than retrying — full VM restores routinely take 30–90+ minutes, which is expected behavior, not a hang.

### 5. Azure Lab Services' auto-shutdown fired during testing, creating ambiguous signals
**Problem:** While validating VM state during backup/restore work, the Project 4 auto-shutdown schedule (traced back to Azure Lab Services' first-party identity, per the Project 5 investigation) deallocated `vm-web-dev` at its normal 11 PM trigger — a separate, unrelated event that could easily be mistaken for a backup/restore side effect if the timing wasn't checked carefully.
**Fix:** Cross-referenced the Activity Log timestamp against actual commands run, confirming it was the routine scheduled shutdown and not something caused by the backup/restore testing. Noted that auto-shutdown schedules are worth temporarily disabling during any test that depends on precise VM state (like a DR failover simulation), to avoid ambiguous results.

### 6. Push rejected due to diverged local and remote history
**Problem:** `git push` to the consolidated `azure-cloud-portfolio` repo failed with `[rejected] main -> main (fetch first)`, since the remote repository contained commits (from the earlier subtree consolidation work) that weren't present in the local working copy.
**Fix:** Ran `git pull origin main` to bring the remote's existing history into the local repo before pushing again, rather than force-pushing over it — confirmed afterward that both the newly-added `06-backup-dr/` folder and the previously-consolidated project folders were all present, avoiding any accidental loss of earlier work.

---

## What We Learned

- **A backup isn't proven until you've restored from it.** This is the same discipline that ran through segmentation testing in Project 1 and alert testing in Project 4 — a "Protected" status or a completed backup job is necessary but not sufficient evidence; only a successful, verified restore actually proves the system works.
- **PowerShell's handling of nested command substitution is a recurring source of fragile failures.** This is now a pattern seen across multiple projects (the bulk user script, Terraform import commands, and now the backup policy creation) — writing intermediate output to a file and referencing it explicitly is consistently more reliable than inline substitution.
- **Not every parameter belongs on every subcommand, even within the same command family.** `az backup policy` has several subcommands that share some flags but not others — worth checking a command's actual accepted parameters rather than assuming consistency across a whole command group.
- **Long-running Azure operations (restores, backups) need to be trusted to actually take time**, not treated as stuck the moment they don't return instantly — checking job status is the correct diagnostic step, not immediately retrying or cancelling.
- **Automation built in earlier projects can interfere with testing in later ones.** The Project 4 auto-shutdown schedule firing mid-test in this project is a direct, concrete example of why documenting cross-project dependencies (as the portfolio's master README already does) matters beyond just narrative — it has real operational consequences during hands-on work.
- **A rejected push isn't data loss — it's Git protecting history that already diverged.** Pulling before pushing (rather than force-pushing) preserved the earlier consolidation work already on the remote while still successfully adding this project's new folder, reinforcing the same discipline used throughout this portfolio: understand what a warning/error is actually protecting against before working around it.

---

## Recovery Objectives Analysis

**RPO (Recovery Point Objective):** With daily backups, maximum data
loss in a disaster scenario is 24 hours — the gap between the last
successful backup and the point of failure.

**RTO (Recovery Time Objective):** Measured during this project's
test restore: backup completion took approximately 57 minutes, and
the full restore-to-running-VM process took approximately 10 minutes.
Total realistic recovery time for this workload: 67 minutes.

**Tradeoffs considered:** A more frequent backup schedule (e.g., every
4 hours) would reduce RPO but increase storage cost and backup job
overhead. For a workload at this scale, daily backups represent a
reasonable balance — this would change for a production system with
a lower acceptable data-loss threshold.

---

## Files in This Project

```
Project6-BackupDR-Walkthrough.md   # Full step-by-step walkthrough
defaultpolicy.json                  # Retrieved default VM backup policy (working file)
screenshots/
├── vault-and-policy-config.png
├── backup-job-completed.png
├── restore-job-completed.png
├── restored-vm-data-verification.png
└── rto-rpo-writeup.png
```
