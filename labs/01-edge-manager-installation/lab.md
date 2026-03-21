---
title: "Use Case 4.5.1 — Red Hat Edge Manager installation"
description: "Install RHEM on RHEL; verify UI + flightctl CLI."
tags: [rhem, install, rhel]
---

# Lab 4.5.1 — RHEM installation (RHEL)

**Prereqs:** RHEL host for RHEM + Keycloak — **16 GB RAM, 4 vCPU, 70 GB disk** (per test plan). Use a DNS name that resolves to this host if possible. The browser UI uses `https://<DNS_Name>/` and the `flightctl` CLI uses `https://<DNS_Name>:3443`.

## Step 1 — Record environment

```bash
cat /etc/os-release
uname -r
free -h
nproc
df -h /
```

## Step 2 — Register the host and install Red Hat Edge Manager

Use **[Installing Red Hat Edge Manager on RHEL](https://docs.redhat.com/en/documentation/red_hat_edge_manager/1.0/html/installing_red_hat_edge_manager_on_red_hat_enterprise_linux/)** as the source of truth. This lab keeps the install flow in one place for the common path on a fresh RHEL VM.

```bash
# Check registration state
sudo subscription-manager status

# If the host is not registered yet:
sudo subscription-manager register --username YOUR_RHSM_USER --password YOUR_RHSM_PASSWORD
# Or use an activation key instead:
# sudo subscription-manager register --org=YOUR_ORG --activationkey=YOUR_KEY

sudo subscription-manager attach --auto
sudo subscription-manager refresh
sudo subscription-manager repos --list-enabled

sudo dnf install -y podman
podman --version
sudo podman login registry.redhat.io

sudo subscription-manager repos --enable edge-manager-1.0-for-rhel-9-x86_64-rpms
sudo dnf install -y flightctl-services flightctl-cli
sudo systemctl enable --now flightctl.target
sudo systemctl list-units 'flightctl-*.service'
```

If `subscription-manager repos --enable ...` reports no repositories available, the host is not attached to a subscription that includes Edge Manager yet.

## Step 3 — Create the first admin account

At this point, Red Hat Edge Manager is installed and running. Before opening the UI or using `flightctl login`, create the first local admin account inside the `flightctl-pam-issuer` container.

```bash
export RHEM_ADMIN_USER="CHANGEME-admin"
export RHEM_ADMIN_PASSWORD='CHANGEME-password'

sudo podman exec -i flightctl-pam-issuer groupadd flightctl-admin
sudo podman exec flightctl-pam-issuer adduser "$RHEM_ADMIN_USER"
sudo podman exec -i flightctl-pam-issuer sh -c "echo '${RHEM_ADMIN_USER}:${RHEM_ADMIN_PASSWORD}' | chpasswd"
sudo podman exec -i flightctl-pam-issuer usermod -aG flightctl-admin "$RHEM_ADMIN_USER"
```

Use this same username and password for both the browser login and the `flightctl` login below.

## Step 4 — Verify the web UI

```bash
# Web UI:
export RHEM_HOST="CHANGEME-rhem.example.com"
export RHEM_UI_URL="https://${RHEM_HOST}/"
curl -skI "$RHEM_UI_URL" | head -5
```

Open the same URL in a browser and sign in with `$RHEM_ADMIN_USER` and `$RHEM_ADMIN_PASSWORD`.

Use `https://<host>/` for the browser UI. Do not use `:3443` in the browser; `:3443` is the CLI/API endpoint and may return `404 page not found` there.

## Step 5 — Install and auth **flightctl** CLI

```bash
# CLI/API endpoint:
export RHEM_API_URL="https://${RHEM_HOST}:3443"
flightctl version
flightctl login --url "$RHEM_API_URL" --username "$RHEM_ADMIN_USER" --password "$RHEM_ADMIN_PASSWORD"
flightctl whoami
```

If the certificate is self-signed, the CLI prompts to continue with an insecure connection. That is expected in a lab setup.

## Step 6 — Success check

- [ ] UI login works  
- [ ] `flightctl` authenticates and returns identity / empty resource list is OK  

**Done.**
