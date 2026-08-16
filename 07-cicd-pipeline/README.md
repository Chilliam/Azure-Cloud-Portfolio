# Project 7: CI/CD Pipeline (GitHub Actions + Terraform) — README

## Overview

This project automated the manual `terraform plan` / `terraform apply` workflow used throughout Projects 3 and its reconciliation work — every pull request against the Terraform folder now automatically runs a plan for review, and merging to `main` automatically applies it. Authentication uses OIDC federated credentials rather than a stored client secret, so there's no long-lived credential sitting in GitHub to leak or rotate.

---

## Objectives Completed

- **Azure AD App Registration and Service Principal** created specifically for GitHub Actions, scoped to Contributor on `rg-project3-tf-dev` only — not the subscription
- **OIDC federated credentials** configured for both the `main` branch and pull requests, eliminating the need to store any client secret in GitHub at all
- **GitHub Actions workflow** (`.github/workflows/terraform.yml`) with two jobs: `plan` on pull requests (posts a comment), `apply` on push to `main`
- **End-to-end pipeline tested with a real pull request** — confirmed the plan job ran automatically, posted a comment, and the apply job ran automatically on merge
- **A genuine formatting failure caught by the pipeline** — not a contrived test, but a real `terraform fmt -check` failure from formatting drift accumulated across many manual edits earlier in the project series
- **A local pre-commit hook** added afterward to catch formatting issues before they ever reach GitHub Actions, closing the gap that allowed the drift to accumulate in the first place

### Verification Checklist (all confirmed)

- [x] App registration created with federated credentials — zero secrets stored in GitHub
- [x] Role assignment scoped to just `rg-project3-tf-dev`, not the subscription
- [x] `plan` job runs automatically on PR open, posts a comment
- [x] `apply` job runs automatically on merge to `main`
- [x] A real test change flowed through the whole pipeline successfully
- [x] Local pre-commit hook installed and verified in both directions (blocks bad formatting, allows good formatting through)

---

## Challenges We Ran Into (and How We Resolved Them)

### 1. PowerShell stripped quotes from inline JSON for the federated credential command
**Problem:** `az ad app federated-credential create --parameters '{"name":"...",...}'` failed with `Failed to parse string as JSON` and `Expecting property name enclosed in double quotes` — PowerShell's quoting rules strip embedded double quotes differently than bash, so Azure CLI received malformed JSON even though the command looked correct as typed.
**Fix:** Escaped every double quote inside the JSON string with a backslash (PowerShell-specific quoting, per Azure CLI's own documented guidance for this exact issue), and for the more failure-prone commands, switched to writing the JSON to a file first and referencing it with `@filename` — the same file-based pattern that had already proven more reliable than inline substitution in Project 6's backup policy creation.

### 2. Lost track of the `$appId` variable between PowerShell sessions
**Problem:** `$appId` was only ever stored in-memory as a session variable from Step 1; closing and reopening the terminal lost the value, causing later commands referencing `$appId` to fail silently or reference nothing.
**Fix:** Re-queried the app registration by its display name (`az ad app list --display-name "..." --query "[0].appId" -o tsv`) to repopulate the variable in a fresh session, and additionally saved the value to a local file for durability going forward.

### 3. terraform fmt -check failed in the pipeline on a genuine formatting issue
**Problem:** The `plan` job's format-check step failed with exit code 3, blocking the workflow — not a pipeline misconfiguration, but real formatting drift in `main.tf` accumulated from many manual edits across earlier sessions in this project series.
**Fix:** Ran `terraform fmt` locally to auto-correct the formatting, reviewed the diff to confirm it was whitespace-only, and pushed the fix. Recognized this as CI/CD doing exactly what it's supposed to do — catching a real, previously-invisible inconsistency — rather than treating the failure as a bug in the pipeline itself.

### 4. The pre-commit framework failed with a Windows-specific bash path error
**Problem:** After adopting the industry-standard `pre-commit` Python framework (with the `antonbabenko/pre-commit-terraform` hook collection) to catch formatting issues before they reached GitHub, committing failed with `ExecutableNotFoundError: Executable /bin/bash not found` — a known, documented issue where the framework's Terraform hooks are implemented as bash scripts invoked via a literal `/bin/bash` path that doesn't resolve on native Windows/PowerShell outside Git Bash's own shell environment.
**Fix:** Uninstalled the `pre-commit` framework (`pre-commit uninstall`) and reverted to a plain native Git hook (`.git/hooks/pre-commit`, a hand-written bash script) instead. Git itself invokes hook scripts via their shebang line regardless of which shell initiated the commit, so this sidesteps the framework's Python-subprocess-calling-`/bin/bash` path entirely. Verified the native hook correctly blocks a deliberately-broken commit and allows a correctly-formatted one through, in both directions.

---

## What We Learned

- **File-based parameter passing continues to be more reliable than inline JSON across this entire project series.** The federated credential quoting issue is the same underlying PowerShell fragility already seen with the bulk user script and the Terraform import blocks — worth defaulting to a file from the start on any command involving embedded JSON, rather than trying inline substitution first.
- **A CI/CD pipeline's job is to surface problems that were already there, not create new ones.** The `terraform fmt` failure felt like a pipeline problem at first glance, but it was actually the pipeline correctly doing its job — catching formatting drift that had been silently accumulating and would never have been caught by manual, inconsistent local habits.
- **"Industry standard" doesn't mean "frictionless on every platform."** The `pre-commit` framework is genuinely the more common real-world tool, but it introduced a real, well-documented Windows compatibility gap. Recognizing the limitation, verifying it against others' reported experience, and making a deliberate choice to use a simpler alternative is a stronger outcome than blindly forcing the "correct" tool to work.
- **OIDC federated credentials are worth the extra setup step over a stored secret.** The App Registration → Service Principal → Federated Credential chain is more conceptually involved than pasting a secret into GitHub, but it means there is nothing in this pipeline's configuration that could leak and grant standing access — a meaningfully stronger security posture for a very small amount of additional complexity.
- **Testing a safeguard in both directions matters, not just one.** Confirming the pre-commit hook blocks bad formatting was necessary but not sufficient — confirming it also lets correctly-formatted commits through cleanly was equally important, since a hook that blocks everything is just as broken as one that blocks nothing.

---

## Files in This Project

```
.github/workflows/terraform.yml     # CI/CD pipeline definition
.git/hooks/pre-commit                # Local formatting safeguard (native, not committed to repo)
Project7-CICD-Walkthrough.md         # Full step-by-step walkthrough
```
