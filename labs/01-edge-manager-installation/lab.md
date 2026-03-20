---
title: "Use Case 4.5.1 — Red Hat Edge Manager installation"
description: "Install RHEM on RHEL; verify UI + flightctl CLI."
tags: [rhem, install, rhel]
---

# Lab 4.5.1 — RHEM installation (RHEL)

**Prereqs:** RHEL host for RHEM + Keycloak — **16 GB RAM, 4 vCPU, 70 GB disk** (per test plan).

## Step 1 — Record environment

```bash
cat /etc/os-release
uname -r
free -h
nproc
df -h /
```

## Step 2 — Follow product install (replace with your runbook)

Use Red Hat docs: *Enabling Red Hat Edge Manager*, *Installing the Edge Manager CLI*. Paste your approved install commands below when you have them.

```bash
# Example placeholders only — replace with official steps / subscription-manager / image
# sudo dnf install -y CHANGEME-rhem-packages
```

## Step 3 — Verify UI reachable

```bash
# Replace with your RHEM API/UI URL
export RHEM_URL="https://CHANGEME-rhem.example.com"
curl -skI "$RHEM_URL" | head -5
```

Open the same URL in a browser; complete login flow.

## Step 4 — Install and auth **flightctl** CLI

```bash
# After CLI install per docs:
flightctl version
flightctl login --url "$RHEM_URL"
flightctl whoami
```

## Step 5 — Success check

- [ ] UI login works  
- [ ] `flightctl` authenticates and returns identity / empty resource list is OK  

**Done.** Fill `RESULTS.md`.
