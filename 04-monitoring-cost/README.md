# Project 4: Monitoring & Cost Management — README

## Overview

This project set up centralized monitoring for the environment built in Project 1/3, connected a VM to Log Analytics, configured an alert that was verified to actually fire (not just configured), built a custom dashboard, and ran a real cost-optimization pass including auto-shutdown scheduling and a budget alert.

---

## Objectives Completed

- **Log Analytics workspace** (`law-project4-dev`) created and connected to the web VM via the Azure Monitor Agent and a Data Collection Rule
- **Verified data flow** — confirmed performance counter data was actually landing in the workspace by running a live KQL query (`Perf | where ObjectName == "Processor"`) rather than assuming the connection worked
- **CPU metric alert** (`alert-high-cpu-web`) configured with an action group, and **proven to actually fire** by generating real load with the `stress` tool and confirming both the alert status changed and the notification email arrived
- **Budget alert** configured at the subscription level to catch unexpected spend early
- **Custom dashboard** combining a Markdown summary tile, a live CPU metrics chart, and a pinned Log Analytics query tile
- **Cost optimization pass** — reviewed Azure Advisor recommendations, configured auto-shutdown schedules on both web VMs, and right-sized VM selection after hitting a real-world SKU availability issue
- **Written cost case study** documenting the actual optimization steps taken and their impact, tying the whole project together into a portfolio-ready narrative

---

## Challenges We Ran Into (and How We Resolved Them)

### 1. Standard_B1s wasn't available in the target region/subscription
**Problem:** The originally planned VM size (`Standard_B1s`) failed to deploy — this VM series is being phased out and increasingly restricted on free-trial subscriptions.
**Fix:** Researched current Azure VM pricing/availability and switched to `Standard_B2ats_v2`, which is in the actively-supported Bsv2 family and — notably — falls under Azure's free-account allowance of 750 free hours/month for 12 months, making it not just cheaper but potentially free for the duration of the trial.

### 2. A Project 2 governance policy blocked deployment into a new resource group
**Problem:** Deploying into `rg-project3-dev` failed with an `InvalidTemplate`/required-tag policy violation — traced back to the "Require a tag on resources" Azure Policy built in Project 2, which had been scoped to the **subscription** level rather than just its intended resource group, so it was silently enforcing tag requirements everywhere.
**Fix:** Deleted the overly-broad policy assignment and recreated it scoped specifically to `rg-project2-dev`, confirming via `az policy assignment list` that the new scope was correctly narrowed before retrying the blocked deployment.

### 3. az vm auto-shutdown failed with a missing required argument
**Problem:** `az vm auto-shutdown` doesn't infer the VM's region automatically the way some other commands do.
**Fix:** Added the `--location` flag explicitly, confirming the correct region first with `az vm show --query location`.

### 4. Portal navigation friction across multiple blades
**Problem:** Several portal screens didn't behave as expected during this project:
  - The Logs screen defaulted to a **Tables** browser pane rather than an open query editor, making it look like no query box existed
  - **Action Groups** wasn't easily discoverable via top-level search in some navigation paths
  - The **Alerts** blade threw a generic "Error displaying your content" rendering error
  - The Log Analytics **"Pin to dashboard"** button wasn't visible/reachable during dashboard building
  - Global portal **Dashboard search** didn't return a result at all in one instance
**Fix:** Worked through each with a layered approach: hard browser refresh/incognito window first (resolved the rendering error), direct deep-link URLs to bypass broken intermediate screens, the portal's hamburger menu as an alternative to top search, and — critically — switching to **Azure CLI equivalents** (`az monitor action-group create`, `az monitor log-analytics query`) as reliable fallbacks whenever a specific portal blade kept failing rather than continuing to fight the UI indefinitely.

### 5. Uncertainty about which visualization tool was "correct"
**Problem:** After building the classic Azure Portal dashboard, it wasn't clear whether Grafana was the expected/more modern tool instead.
**Fix:** Researched Microsoft's actual current guidance and confirmed the classic dashboard remains a fully valid, standard choice for this scope of project — Grafana-based options exist for more complex, multi-source, or Kubernetes-heavy scenarios, which this project didn't require. Documented the reasoning rather than switching tools unnecessarily.

### 6. Resource and VM naming drifted across the project's own documentation
**Problem:** The walkthrough initially referenced `rg-project1-dev` and `vm-web-01` (the Project 1 portal-built naming), which didn't match the actual Terraform-managed environment (`rg-project3-tf-dev`, `vm-web-dev`) this project was actually being run against.
**Fix:** Updated all references throughout the document for consistency, keeping a single clear note for anyone using the alternate Project 1 portal-built environment instead.

---

## What We Learned

- **"Configured" isn't the same as "verified working."** The CPU alert wasn't trusted until it was actually forced to fire with real load and the notification was confirmed received — the same discipline that mattered in Project 1's segmentation proof applies just as much to monitoring and alerting.
- **Governance policies can have consequences far outside their intended scope.** A policy built and tested correctly in one project (Project 2) caused a confusing, unrelated failure in a completely different project weeks later, simply because of an overly broad scope. Always double-check policy assignment scope, not just its logic.
- **When a specific portal blade keeps failing, switching to CLI is a legitimate fix, not a workaround.** Several portal rendering issues in this project were resolved faster and more reliably by using the CLI equivalent than by continuing to troubleshoot browser-side rendering bugs.
- **VM size availability is a real, evolving constraint, not just a one-time setup detail.** Azure regularly retires or restricts older VM SKUs, especially on free-trial subscriptions — worth checking current availability with `az vm list-skus` rather than assuming a size used in a tutorial is still deployable.
- **Cost optimization is more credible with real numbers than hypothetical ones.** Tying the case study to actual observed CPU utilization and real Azure pricing data, rather than estimated/invented figures, made the deliverable genuinely defensible rather than just an exercise.

---

## Files in This Project

```
Project4-Monitoring-Cost-Walkthrough.md   # Full step-by-step walkthrough
Project4-Step6-Expanded.md                 # Detailed dashboard-building breakdown
screenshots/                                # Alert firing proof, dashboard, cost case study evidence
```
