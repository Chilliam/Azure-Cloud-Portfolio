# Azure Cloud Portfolio — Will Crenshaw

**IT Support Technician transitioning to Azure Administrator / Cloud Architect.**
This repository documents a series of hands-on Azure projects built to close the gap between IT Support experience and cloud infrastructure roles — covering core networking, identity/governance, infrastructure as code (Bicep *and* Terraform), monitoring, cost management, automation, backup and disaster recovery, CI/CD, and security hardening, all built and verified in a single live Azure environment that grew iteratively across every project.

Each project was deliberately built to **prove** claims rather than just configure and assume — segmentation is tested by actually attempting blocked connections, alerts are tested by generating real load, and automation is tested by running it manually before trusting a schedule. That discipline runs through every project below.

---

## Certification Progress

| Cert | Status |
|---|---|
| AZ-900 (Azure Fundamentals) | Completed |
| AZ-104 (Azure Administrator Associate) | Sat July 2026, scored just below passing — currently on a 5-week rebalanced retake study plan targeting Monitor & Maintain, Networking, and Identities & Governance |
| AZ-305 (Solutions Architect Expert) | Planned, after 1–2 years of real Azure job experience |

Study tools: a self-contained offline AZ-104 quiz app (HTML) and an Excel study tracker with domain confidence ratings and practice test logging.

---

## Projects

| # | Project | What It Demonstrates | Link |
|---|---|---|---|
| 1 | **Core Infrastructure Build** | Manual portal build of a segmented two-tier network — VNet, subnets, NSGs, load balancer, verified network segmentation via jump-box SSH proof | [`01-core-infrastructure/`](./01-core-infrastructure/README.md) |
| 2 | **Identity & Governance** | Entra ID users/groups, custom least-privilege RBAC role (verified by actually testing the boundary), Conditional Access + MFA, Azure Policy governance | [`02-identity-governance/`](./02-identity-governance/README.md) |
| 3 | **Infrastructure as Code** | Project 1's architecture rebuilt as modular Bicep, then again in Terraform — load balancer, NAT Gateway, and a second VM added to both | [`03-infrastructure-as-code/`](./03-infrastructure-as-code/README.md) |
| 3b | ↳ Terraform Edition | Terraform-specific build notes, comparing idioms directly against the Bicep version | [`03-infrastructure-as-code/terraform/README.md`](./03-infrastructure-as-code/terraform/README.md) |
| 4 | **Monitoring & Cost Management** | Log Analytics, an alert proven to actually fire under real load, a custom dashboard, and a cost optimization case study with real numbers | [`04-monitoring-cost/`](./04-monitoring-cost/README.md) |
| 5 | **Automation** | Bulk user provisioning (Azure CLI) and scheduled VM start/stop via Azure Automation with a system-assigned managed identity — no stored credentials anywhere | [`05-automation/`](./05-automation/README.md) |
| — | **Terraform Drift Reconciliation** | Audited the live environment against Terraform state after Projects 4 and 5 introduced drift, and reconciled every resource back into code via `terraform import` | [`03-infrastructure-as-code/terraform/RECONCILIATION.md`](./03-infrastructure-as-code/terraform/RECONCILIATION.md) |
| 6 | **Backup & Disaster Recovery** | Recovery Services Vault, a real backup + verified restore, RTO/RPO analysis with observed timings (57 min backup, 10 min restore) | [`06-backup-dr/`](./06-backup-dr/README.md) |
| 7 | **CI/CD Pipeline** | GitHub Actions running Terraform plan/apply with OIDC federated credentials — no stored secrets, plus a local pre-commit formatting safeguard | [`07-cicd-pipeline/`](./07-cicd-pipeline/README.md) |
| 8 | **Security Hardening** | Azure Bastion replacing public SSH access, Key Vault for centralized secrets, and a Private Endpoint for Log Analytics via AMPLS — with DNS resolution proven private-vs-public from inside vs. outside the VNet | [`08-security-hardening/`](./08-security-hardening/README.md) |
| 9 | **Multi-Region High Availability** | Planned — Traffic Manager failover across two Azure regions with a real simulated outage test | *In progress* |

---

## How These Projects Connect

This isn't five unrelated exercises — it's one environment that grew iteratively, the way real infrastructure actually does:

- **Project 1** established the network and the segmentation pattern (public web tier, private data tier) that every later project builds on top of.
- **Project 2**'s groups (`grp-project2-admins`, `grp-project2-readers`) are the actual target of Project 5's bulk user provisioning script — not a separate, disconnected identity exercise.
- **Project 3** reproduced Project 1's design as code in two different tools, then extended it with a load balancer, NAT Gateway, and a second VM.
- **Project 4** and **Project 5** both operate directly against Project 3's Terraform-managed resource group (`rg-project3-tf-dev`) — monitoring and automating the same VMs, not a fresh environment.
- The **Terraform Reconciliation** work exists because Projects 4 and 5 were partly built through CLI/portal rather than Terraform, creating real drift — which was then diagnosed and fixed, including tracing an unexpected VM shutdown back to its actual root cause using Activity Log.
- **Project 6** backs up `vm-data-dev`, the same data-tier VM whose segmentation was first proven in Project 1.
- **Project 7**'s pipeline manages the same Terraform code from Project 3 and the reconciliation work — and its pre-commit formatting hook caught a real issue during **Project 8**, a concrete example of one project's safeguards protecting a later, unrelated one.
- **Project 8** directly follows through on an idea flagged during Project 3's original SSH NAT rule troubleshooting, replacing that workaround with Azure Bastion, and reconciles its own new resources back into the same Terraform state and GitHub repo established in Project 3 and Project 7.

## Architecture Diagrams

All `.drawio` diagrams (editable in [app.diagrams.net](https://app.diagrams.net)) live in [`diagrams/`](./diagrams/), including:
- Project 1 network diagram (portal-built)
- Full current-state environment diagram (professional style, color-coded by resource category, reflecting everything tracked in Terraform, including Project 8's Bastion and Private Endpoint additions)
- Azure-icon variant of the current-state diagram, using draw.io's built-in Azure shape library

## Tech Stack

`Azure (Entra ID, VNet/NSG/Load Balancer, Log Analytics, Azure Monitor, Azure Automation, Recovery Services Vault, Key Vault, Bastion, Private Link) · Bicep · Terraform · Azure CLI · PowerShell · GitHub · GitHub Actions`

## Key Skills Demonstrated Across This Portfolio

- Network segmentation design and verification (not just configuration)
- Least-privilege RBAC and Conditional Access rollout discipline
- Infrastructure as Code in two different tools, including provider-level idiom differences
- Real cost governance (auto-shutdown, budget alerts, right-sizing against actual utilization data)
- Credential-free automation and CI/CD using managed identities and OIDC federated credentials
- Configuration drift detection and reconciliation — a realistic maintenance skill most portfolios don't demonstrate, exercised repeatedly across Projects 5, 7, and 8
- Methodical troubleshooting across CLI, PowerShell, portal UI, and authentication layers, including recognizing genuine tool/SDK bugs versus configuration mistakes
- Backup/restore verification and RTO/RPO analysis using real, observed timings rather than estimates
- Network security hardening — replacing public-facing access paths with Bastion and Private Endpoints, and proving the reduction in attack surface rather than assuming it
- Reading Terraform plan output critically enough to catch and avoid multiple near-miss destructive changes before applying them

---

## About

Built by Will Crenshaw as part of a structured transition from IT Support into Azure Cloud Administration. Background includes enterprise Microsoft 365/Intune/Entra ID administration, calendar delegation and mailbox management for a multi-user environment, and hands-on troubleshooting across identity, device management, and email systems.
