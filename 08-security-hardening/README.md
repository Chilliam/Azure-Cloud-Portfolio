# Project 8: Security Hardening (Key Vault, Bastion, Private Endpoints) — README

## Overview

This project follows through on an idea flagged back in Project 3's SSH NAT rule troubleshooting: replace the load balancer's SSH NAT rule with Azure Bastion, move SSH key storage into Key Vault instead of loose local files, and add a Private Endpoint so monitoring traffic stays off the public internet. It's the project that turns "it works" into "it's actually secured the way a real environment should be."

**Status:** Complete. All three objectives — Key Vault, Bastion replacing public SSH access, and a Private Endpoint for Log Analytics with proven private DNS resolution — are finished and verified.

---

## Objectives Completed So Far

- **Key Vault** (`kv-project6-dev`) created in `rg-project3-tf-dev`
- **Access policy configured**, granting the signed-in account permission to manage secrets
- **SSH private key stored as a Key Vault secret** (`project3-ssh-private-key`) — a reference/backup copy demonstrating centralized secrets management, distinct from the local key still used day-to-day
- **`AzureBastionSubnet` created** — the dedicated, correctly-named `/26` subnet Bastion requires, carved out of `vnet-dev` alongside `web-subnet` and `data-subnet` with no address overlap
- **Azure Bastion host deployed** (`bastion-dev`) with its own public IP (`pip-bastion-dev`) — confirmed `provisioningState: Succeeded`
- **Bastion authentication confirmed working** — successfully connected to `vm-web-dev` via Bastion's browser-based SSH session using the uploaded private key, proving the access path itself is valid
- **Native client Bastion connection confirmed stable** — after isolating the browser session's instability, connected successfully and reliably via `az network bastion ssh` (native client tunneling), fully proving the access path with no lingering stability concerns
- **SSH NAT rule removed from the load balancer** (`natrule-ssh-web`) — Bastion is now the sole path to SSH into the VMs, with no port-forwarding rule left on the public-facing load balancer
- **Public-facing `Allow-SSH` NSG rule removed** from `nsg-web` — no rule remains permitting SSH from the internet to the web subnet
- **Attack surface reduction proven, not assumed** — confirmed the original SSH path (`ssh -p 2222` to the load balancer's public IP) now times out completely, while HTTP traffic on the same public IP continues to work normally, confirming a surgical removal of SSH access only
- **All Project 8 resources reconciled into Terraform** — Key Vault, both new subnets, Bastion's public IP, and the Bastion host itself imported and organized into a dedicated `security.tf` file
- **Two genuinely undocumented resources discovered and imported during reconciliation** — `vm-web2-dev` and its load balancer backend pool association existed in Azure but were never tracked in Terraform state; both imported rather than left as drift
- **A near-miss VM destroy identified and avoided before applying** — a plan mismatch on `vm-web2-dev`'s size and `custom_data` would have destroyed and recreated a real running VM; corrected the configuration to match reality instead of letting Terraform "fix" a working resource
- **`terraform.tfstate` and its backup removed from Git tracking** — discovered both files had been committed to the repository before `.gitignore` existed, despite the `.gitignore` correctly listing `*.tfstate`; untracked them without affecting local Terraform operation
- **Full state reconciled to zero drift and pushed to GitHub** — `terraform plan` confirmed `No changes` before the final commit and push
- **Azure Monitor Private Link Scope (AMPLS) created** and connected to `law-project4-dev`, the correct architecture for a Private Endpoint targeting Log Analytics/Azure Monitor rather than a direct Private Endpoint against the workspace
- **Private Endpoint created** (`pe-law-project4`) in `privatelink-subnet`, targeting the AMPLS
- **Two Private DNS zones created and linked to `vnet-dev`** (`privatelink.oms.opinsights.azure.com` and `privatelink.ods.opinsights.azure.com`) — Azure Monitor Private Link requires multiple zones covering different parts of the ingestion/query pipeline, not a single zone
- **Private DNS resolution proven, not assumed** — queried the workspace's actual ingestion hostname from both outside and inside the VNet: from the local machine it resolved to a public IP (`20.42.73.140`); from inside `vm-web-dev` via Bastion, the identical hostname resolved to `10.0.4.5`, a private IP inside `privatelink-subnet`

### Verification Checklist (progress so far)

- [x] Key Vault created and accessible
- [x] SSH private key stored as a secret
- [x] `AzureBastionSubnet` created with correct name and size
- [x] Bastion host deployed and confirmed healthy
- [x] Bastion authentication succeeded (session established, `whoami`/`hostname` reachable before disconnect)
- [x] Stable, sustained Bastion session — achieved via native client (`az network bastion ssh`) after isolating browser-specific instability
- [x] Old SSH NAT rule removed from load balancer
- [x] Public-facing `Allow-SSH` NSG rule removed
- [x] Confirmed direct SSH from local machine no longer works (`ssh -p 2222` to the load balancer's public IP times out; HTTP on the same IP still works normally)
- [x] All Project 8 resources imported into Terraform with zero remaining drift
- [x] `terraform.tfstate` and backup untracked from Git
- [x] Changes committed and pushed to GitHub
- [x] Private Endpoint created for Log Analytics (via AMPLS, the correct architecture for this resource type)
- [x] DNS resolution confirmed returning a private IP from inside the VNet (`10.0.4.5`) vs. a public IP from outside (`20.42.73.140`) for the identical hostname

---

## Resolved Issue: Bastion Browser Session Instability

**Problem:** Azure Bastion's browser-based SSH session repeatedly disconnected shortly after a successful connection, with two distinct error messages observed:
- *"The Bastion Host has closed the connection because there has been no response from your browser for long enough that it appeared to be disconnected."*
- *"The network connection to the Bastion Host appears unstable."*

**Investigation performed, ruling out causes one at a time:**
1. Confirmed the underlying Bastion deployment itself was healthy (`provisioningState: Succeeded`) — ruled out a broken/failed deployment
2. Tested from a completely different network (mobile hotspot) — same error, ruled out local Wi-Fi/network quality
3. Tested in a private/incognito browser window — same error, ruled out a specific browser session's cache/state
4. Tested in a different browser entirely, also in incognito mode — same error, ruled out both a specific browser and its extensions
5. Confirmed the Bastion host was already on **Standard SKU** — ruled out the Basic-tier session-resource limitation as the cause

**Root cause found:** none of the above — the actual issue was that **native client support** (`enableTunneling`) was not turned on. This is a separate, non-default feature flag from the SKU tier itself; having Standard SKU alone does not enable it. Attempting `az network bastion ssh` surfaced this directly with a clear error: *"Bastion Host SKU must be Standard or Premium and Native Client must be enabled."*

**Fix:**
```powershell
az network bastion update --resource-group rg-project3-tf-dev --name bastion-dev --enable-tunneling true
```

**Resolution confirmed:** connected successfully and reliably to `vm-web-dev` via the native CLI client (`az network bastion ssh`), with no further disconnects. This both resolved the immediate access problem and confirmed the earlier browser-based instability was specific to the browser/WebSocket session path, not a flaw in the underlying Bastion deployment, network, or Standard SKU configuration.

**Why this is worth documenting in full rather than just noting the fix:** the systematic elimination process (network → browser → extensions → SKU tier) was necessary to arrive at the actual cause, since none of the more commonly-suspected explanations turned out to be correct. The real issue — a distinct, easy-to-overlook feature flag separate from SKU tier — was only found by trying an alternative access method (the native client) rather than continuing to troubleshoot the browser path directly.

## Note: VM Auto-Shutdown Coincided with a Bastion Session

**Observation:** During native client testing, `vm-web-dev` was deallocated mid-session. Given the Project 5 investigation already traced the Project 4 auto-shutdown schedule back to Azure Lab Services' first-party identity firing on its normal 11 PM daily trigger, this is very likely the same routine mechanism rather than anything caused by Bastion or the SSH session itself — consistent with previously-documented, expected behavior in this environment rather than a new issue.

---

## Challenges We Ran Into (and How We Resolved Them)

### 1. Bastion browser session disconnected with a reproducible instability error
See "Resolved Issue" section above — root cause was native client support (`enableTunneling`) not being enabled, a separate setting from SKU tier, found by systematically eliminating network, browser, and extension causes before trying an alternative access method.

### 2. main.tf appeared empty mid-project, threatening to lose the entire core configuration
**Problem:** While adding the Key Vault and Bastion resource blocks, `main.tf` was found to be empty — a serious scare given the file also contained the VNet, VMs, load balancer, and NAT Gateway configuration built across Projects 3 and the earlier drift reconciliation.
**Fix:** Confirmed Terraform *state* was still fully intact (`terraform state list` showed every resource) even though the local file was empty — meaning nothing in Azure was actually at risk. Restored the file's content from Git history rather than attempting to reconstruct it from memory, confirming the recovered version matched via `terraform plan`.

### 3. Data source syntax typed directly into PowerShell instead of the file editor
**Problem:** `data "azurerm_client_config" "current" {}` — valid Terraform/HCL syntax — was typed directly into the PowerShell terminal rather than pasted into `main.tf`, producing a PowerShell parser error, since PowerShell has its own unrelated `data` keyword.
**Fix:** Recognized the error as coming from the wrong interpreter entirely (PowerShell, not Terraform) and moved the syntax into the actual file via `code main.tf` instead.

### 4. A plan showed 5 resources marked for destruction, including the entire NAT Gateway stack
**Problem:** After the `main.tf` recovery, a `terraform plan` showed 5 resources — the NAT Gateway, its public IP, and both association resources — marked for destruction. Since these provide outbound internet access for VMs with no public IP of their own, applying this would have broken connectivity for `vm-web2-dev` and `vm-data-dev`.
**Fix:** Recognized the cause immediately: resources present in Terraform *state* but missing from the *configuration file* are interpreted by Terraform as "no longer wanted," not left alone. Confirmed the NAT Gateway blocks were genuinely absent from the recovered `main.tf`, retrieved the correct blocks from Git history, and re-added them with resource names matching exactly what state already tracked. Re-ran `plan` and confirmed the destroy count dropped to zero for these resources before proceeding further.

### 5. Bastion host repeatedly marked for full replacement due to an `ip_configuration` naming mismatch
**Problem:** Even after the NAT Gateway was resolved, `terraform plan` showed the Bastion host needing to be destroyed and recreated. The cause: Azure had auto-named the host's internal IP configuration `bastion_ip_config` (underscore) when created via `az network bastion create`, but the Terraform block specified a different value — first `bastion-ipconfig`, then an intermediate typo `bastion-ip_config` — neither of which matched exactly.
**Fix:** Compared the plan's diff character-by-character against the actual Azure-assigned name and corrected the Terraform block to the exact value (`bastion_ip_config`), avoiding an unnecessary Bastion rebuild that would have cost another 5-10 minute provisioning wait and a new public IP for no real benefit.

### 6. A VM's managed identity would have been silently removed
**Problem:** The same plan showed `vm-web-dev`'s system-assigned managed identity being stripped, since it existed in Azure but wasn't declared in the Terraform configuration.
**Fix:** Investigated via Activity Log whether the identity's origin was traceable to any prior project work; found no clear record of intentional creation. Rather than assume it was safe to remove, added a matching `identity { type = "SystemAssigned" }` block to the `web_vm` resource to preserve it, erring toward not silently changing a live resource's security posture without a confirmed reason.

### 7. Two real resources existed in Azure with no Terraform tracking at all
**Problem:** Applying the plan failed with "a resource with this ID already exists" for both `vm-web2-dev` and its load balancer backend pool association — genuine drift where these resources were created outside this particular Terraform state.
**Fix:** Imported both directly with `terraform import`, using the exact (including compound, pipe-separated) resource IDs Azure returned.

### 8. Importing vm-web2-dev revealed a mismatch that would have destroyed a real running VM
**Problem:** After import, `terraform plan` showed `vm-web2-dev` needing to be destroyed and recreated — triggered by a `custom_data` (cloud-init) mismatch, compounded by a VM size mismatch (`Standard_DC1ds_v3` in Azure vs. `Standard_B1s` in the config, a leftover from the earlier `Standard_B1s` availability substitution work in Project 4).
**Fix:** Corrected the configuration to match the real, running VM rather than letting Terraform "fix" it — updated the size to `Standard_DC1ds_v3` and removed the `custom_data` block entirely, since `custom_data` only applies at first boot and Terraform has no way to reconcile it against an already-running, imported VM. Re-ran `plan` and confirmed zero destroys before applying.

### 9. terraform.tfstate had been committed to Git despite a correct .gitignore
**Problem:** `git status` showed `terraform.tfstate` and its backup as tracked, modified files — despite the repository's root `.gitignore` correctly listing `*.tfstate` patterns.
**Fix:** Recognized that `.gitignore` only prevents *new* untracked files from being added; it has no retroactive effect on files already tracked from before the ignore rule existed. Used `git rm --cached` to untrack both files without deleting them locally, confirmed with `Test-Path` that the local files remained intact, and verified they no longer appeared in subsequent `git status` output.

### 11. A direct Private Endpoint against the Log Analytics workspace failed with a misleading feature-registration error
**Problem:** `az network private-endpoint create` targeting the workspace directly (`--group-id azuremonitor`) repeatedly failed with `SubscriptionNotRegisteredForFeature: ... Microsoft.Network/AllowPrivateEndpoints`, even after the feature was confirmed `Registered` in the portal and the resource provider was explicitly re-registered.
**Fix:** Research confirmed this exact error — including its oddly-malformed resource path (`resourceGroups//providers/Microsoft.Network/subscriptions/`) — is a known, documented symptom specific to targeting Azure Monitor/Log Analytics with a direct Private Endpoint, unrelated to actual feature registration state. The correct, Microsoft-documented architecture requires an intermediate **Azure Monitor Private Link Scope (AMPLS)** resource connecting the workspace to the Private Endpoint, rather than a direct connection. Created the AMPLS, linked the workspace to it, and retargeted the Private Endpoint at the AMPLS instead — succeeded immediately.

### 12. Initial DNS query returned NXDOMAIN for the workspace's friendly name
**Problem:** `nslookup law-project4-dev.ods.opinsights.azure.com` returned `NXDOMAIN` both from the local machine and from inside the VM.
**Fix:** Discovered this hostname was never valid in the first place — Azure Monitor/Log Analytics ingestion endpoints are addressed by the workspace's GUID (customer ID), not its display name. Retrieved the real customer ID via `az monitor log-analytics workspace show --query customerId` and queried using the correct hostname format instead.

### 13. The correct hostname resolved publicly but not privately, despite the Private Endpoint being healthy
**Problem:** Querying the correct GUID-based hostname succeeded and revealed the real CNAME chain, which passed through `privatelink.ods.opinsights.azure.com` — a zone that had never been created. Only `privatelink.oms.opinsights.azure.com` (a different, similarly-named zone) had been set up.
**Fix:** Recognized that Azure Monitor Private Link depends on multiple private DNS zones covering different parts of the pipeline (`oms` for the connected-sources/agent side, `ods` for data ingestion), not a single zone as initially assumed. Created and linked the missing `privatelink.ods.opinsights.azure.com` zone, then added it to the Private Endpoint's existing DNS zone group alongside the first.

### 14. A verification command was run from the wrong location twice
**Problem:** Twice during DNS troubleshooting, an `nslookup` intended to test resolution from inside the VNet was instead run from the local Windows machine, producing a result (public DNS server, public IP) that looked like a failure but was actually just testing the wrong vantage point.
**Fix:** Cross-checked the DNS server shown in each result (`127.0.0.53`, the Linux systemd resolver, vs. `G3100.mynetworksettings.com`, a home router) to definitively confirm which machine a given query actually ran from before interpreting the result — a useful general habit when a test's outcome depends on *where* it's executed, not just what command was run.

---

## What We've Learned So Far

- **A successful authentication is a different proof point than a stable session, and both matter.** The core security objective of this project — proving no public-facing SSH port is required to reach a VM — was already demonstrated the moment authentication succeeded through Bastion, independent of session stability. That distinction turned out to matter directly: the eventual fix didn't change whether Bastion worked, only how reliably the connection stayed open.
- **Systematic elimination is more valuable than guessing.** Testing network, then browser, then extensions, then SKU tier — one variable at a time — converted a vague "it's broken" into a precise remaining question, and trying a genuinely different access method (the native client) rather than continuing to fight the browser path is what actually surfaced the real cause.
- **A setting can look related to something already checked without actually being the same thing.** Standard SKU and native client support are both Bastion features, but one doesn't imply the other — a good reminder to verify a specific feature is enabled rather than assuming a higher tier includes everything by default.
- **Not every project step resolves cleanly on the first pass, and that's worth documenting honestly** — including how it got resolved, not just that it eventually was.
- **A destroy count in a Terraform plan is a stop condition, not a formality.** Across this project, plans threatening to destroy the NAT Gateway, replace the Bastion host unnecessarily, and destroy a real running VM were all caught before applying, simply by treating any nonzero destroy count as a reason to pause and investigate rather than a number to skim past.
- **Resources missing from a config file but present in state read as "remove this" to Terraform, not "leave this alone."** This is a genuinely important mental model — a `.tf` file isn't just documentation, it's an active instruction set compared directly against state on every plan.
- **`.gitignore` protects the future, not the past.** A correctly-written ignore rule has no effect on files already committed before the rule existed — a lesson that would have been easy to miss without directly comparing `git status` output against the ignore file's contents.
- **Safeguards built in earlier projects paid off directly in this one.** The Project 7 pre-commit hook catching a real formatting issue here is a concrete example of infrastructure built in one project protecting the integrity of work done in a later, unrelated one — the whole portfolio functioning as one connected environment rather than nine isolated exercises.
- **An error message pointing at one cause (feature registration) isn't always the real cause.** The `SubscriptionNotRegisteredForFeature` error was technically accurate in isolation but misleading in context — the actual fix was an architectural one (AMPLS), not a longer wait. Confirming an error against external documentation, rather than only the error text itself, avoided a genuinely open-ended wait for something that was never going to resolve on its own.
- **A resource's friendly name and its actual addressable identity are sometimes different things.** The workspace's display name (`law-project4-dev`) was never a valid DNS hostname — only its GUID-based customer ID was. Worth checking a resource's actual connection documentation rather than assuming a human-readable name doubles as its network identity.
- **Multi-zone DNS dependencies mean one working zone can mask a second missing one.** The first private DNS zone (`oms`) was configured correctly and gave every appearance of being "the" fix, but the actual CNAME chain depended on a second, separate zone (`ods`) that hadn't been created — a reminder to trace a full resolution chain rather than stopping at the first zone that seems relevant.
- **The same command can produce a misleading result if run from the wrong location.** Verifying *where* a diagnostic command actually executed (by checking which DNS server or shell responded) was necessary twice during this project — a good habit whenever a test's validity depends on network context, not just correct syntax.

---

## What to Say About This Project in an Interview

> "I hardened the environment from earlier projects on three fronts. First, I replaced an open SSH port on the load balancer with Azure Bastion, and proved the old path was actually gone by confirming direct SSH timed out afterward, not just that Bastion worked as an alternative. Second, I moved SSH key storage into Key Vault for centralized secrets management. Third, I added a Private Endpoint for our Log Analytics workspace — which turned out to need an Azure Monitor Private Link Scope and two separate DNS zones, not a single direct connection like I initially assumed. I proved that one worked by querying the same hostname from outside and inside the network and getting a public IP versus a private one. Along the way, reconciling everything into Terraform surfaced several real drift issues — including two plans that would have destroyed a NAT Gateway and a running VM if I'd applied them without reviewing the diff first."

## Files in This Project

```
azure-cloud-portfolio/
├── 08-security-hardening/
│   ├── README.md                     # This file
│   └── screenshots/
│       ├── keyvault-and-secret.png
│       ├── bastion-subnet-config.png
│       ├── bastion-successful-auth.png
│       ├── bastion-session-error.png
│       ├── ampls-and-private-endpoint.png
│       └── dns-resolution-public-vs-private.png
└── 03-infrastructure-as-code/terraform/
    ├── main.tf                        # Core network/VM/LB config, drift-corrected
    ├── security.tf                    # Key Vault, Bastion, and related subnets (this project)
    └── .gitignore                     # Now also excludes plan-output*.txt and *.tfplan
```

