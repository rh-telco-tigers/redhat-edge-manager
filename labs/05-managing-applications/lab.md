---
title: "Use Case 4.5.5 — Managing applications on device"
description: "Deploy container app (e.g. New Relic stack via podman-compose image)."
tags: [applications, podman, oci]
---

# Lab 4.5.5 — Deploy application to edge device

**Prereqs:** App image(s) in **OCI registry**; **podman-compose** wrapper image in registry (per observability vendor integration plan). Pull secret if registry is private.

## Step 1 — Target device

```bash
export RHEM_URL="https://CHANGEME-rhem.example.com"
flightctl login --url "$RHEM_URL"
flightctl get devices
export DEVICE_NAME="CHANGEME_DEVICE"
```

## Step 2 — Define application manifest (example shape)

Replace with fields from *Managing applications on an edge device* for your RHEM version.

```yaml
# CHANGEME — example only; align with official API
apiVersion: v1alpha1
kind: Application
metadata:
  name: CHANGEME_APP_NAME
spec:
  deviceSelector:
    matchLabels:
      fleet: rhem-eap
  containers:
    - name: app
      image: CHANGEME_REGISTRY/CHANGEME_IMAGE:tag
```

```bash
# flightctl apply -f application.yaml
```

## Step 3 — Verify from CLI

```bash
flightctl get applications
# flightctl get applications -o yaml
```

## Step 4 — Verify in UI

Edge Manager → device → applications / workloads (per product UI).

## Step 5 — On-device spot check (if SSH/console available)

```bash
# ssh edge@CHANGEME_DEVICE_IP
podman ps
```

## Step 6 — Success check

- [ ] Application **running** and reachable (per app requirements)  
- [ ] Status visible in **UI** and/or **CLI**  

**Done.**
