---
title: "Use Case 4.5.4 — Fleet + bootc swap to app image"
description: "Create fleet with app image template; label device; pull secrets if private OS image."
tags: [fleet, gitops, pull-secrets]
---

# Lab 4.5.4 — Fleet creation and join device

**Prereqs:** Device enrolled. If OS image is **private**, ensure `/etc/ostree/auth.json` on device **before** swap (see *Configuring Container Pull Secrets*). **App image** in AutomationHub per plan.

## Step 1 — CLI login

```bash
export RHEM_URL="https://CHANGEME-rhem.example.com"
flightctl login --url "$RHEM_URL"
```

## Step 2 — Choose device + label (selector)

```bash
flightctl get devices -o wide
```

```bash
export DEVICE_NAME="CHANGEME_DEVICE"
export FLEET_LABEL_KEY="fleet"
export FLEET_LABEL_VALUE="rhem-eap"
flightctl label device "$DEVICE_NAME" "$FLEET_LABEL_KEY=$FLEET_LABEL_VALUE"
```

## Step 3 — Create fleet + device template (YAML)

Create `fleet.yaml` (replace image + fields per your GitOps / UI workflow):

```yaml
# CHANGEME — align field names with your RHEM / flightctl API version
apiVersion: v1alpha1
kind: Fleet
metadata:
  name: rhem-eap-fleet
spec:
  selector:
    matchLabels:
      fleet: rhem-eap
  template:
    spec:
      os:
        image: CHANGEME_REGISTRY/CHANGEME_APP_IMAGE:tag
```

Apply (if supported) or create equivalent in UI:

```bash
# flightctl apply -f fleet.yaml
```

## Step 4 — Confirm fleet membership / rollout

```bash
flightctl get fleets
flightctl get devices
```

## Step 5 — Success check

- [ ] Fleet exists with expected **device template** (app image)  
- [ ] Device has matching label  
- [ ] Device transitions to **app** image (bootc swap) after policy applies  

**Done.** Fill `RESULTS.md`.
