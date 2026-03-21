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

## Step 2 — Install per Red Hat Edge Manager 1.0 on RHEL

Use **[Installing Red Hat Edge Manager on RHEL](https://docs.redhat.com/en/documentation/red_hat_edge_manager/1.0/html/installing_red_hat_edge_manager_on_red_hat_enterprise_linux/)** (`flightctl-services`, `flightctl.target`, Web UI on `https://<DNS_Name>/`, CLI/API on `https://<DNS_Name>:3443`). Example repo: `edge-manager-1.0-for-rhel-9-x86_64-rpms`.

Repo helper: [`prereqs/docs/04-rhem-1-on-rhel.md`](../../prereqs/docs/04-rhem-1-on-rhel.md) (manual install; no automation in this repo). **Register and attach a subscription first** — otherwise `subscription-manager repos` reports *no repositories available*.

```bash
# After: subscription-manager register / attach / refresh (see 04 doc):
# sudo dnf install -y flightctl-services flightctl-cli
# sudo systemctl enable --now flightctl.target
```

Before continuing: complete the **PAM issuer bootstrap** in [`prereqs/docs/04-rhem-1-on-rhel.md`](../../prereqs/docs/04-rhem-1-on-rhel.md). This is a required manual step on the RHEM host. You do need to run the commands that create the first local admin user; the `flightctl login` step later only authenticates with that user.

## Step 3 — Verify UI reachable

```bash
# Web UI:
export RHEM_UI_URL="https://CHANGEME-rhem.example.com/"
curl -skI "$RHEM_UI_URL" | head -5
```

Open the same URL in a browser; complete login flow. Do not use `:3443` for the browser UI check.

## Step 4 — Install and auth **flightctl** CLI

```bash
# After CLI install per docs:
export RHEM_API_URL="https://CHANGEME-rhem.example.com:3443"
flightctl version
flightctl login --url "$RHEM_API_URL"
flightctl whoami
```

## Step 5 — Success check

- [ ] UI login works  
- [ ] `flightctl` authenticates and returns identity / empty resource list is OK  

**Done.**
