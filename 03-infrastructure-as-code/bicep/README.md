# Two-Tier Azure Environment — Infrastructure as Code (Bicep)

## What this is
A parameterized Bicep template that deploys a segmented two-tier
network (web + data) with least-privilege NSG rules, reusable VM
modules, and environment-specific parameter files (dev/prod-ready).

## Why I built it this way
- Modules (network.bicep, vm.bicep) are reusable — the same VM module
  deploys both tiers with different inputs, avoiding duplication.
- The data tier has no public IP and only accepts inbound traffic
  from the web subnet's CIDR range, with an explicit deny-all as the
  final NSG rule — defense in depth over relying on a single control.
- SSH key auth only (no passwords) to reflect a real production
  security baseline.

## Architecture diagram
[image or ASCII diagram here]

## How to deploy
[deployment steps]

## Lessons learned
[1-2 honest sentences — e.g., "Initially used a single NSG for both
subnets, then split them after realizing that made the least-privilege
rule impossible to express cleanly."]
