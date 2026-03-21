---
title: "Use Case 4.5.2 — bootc / Image Mode images"
description: "Build base (enrollment) + app (e.g. SSM) images; push to AutomationHub; export ISO."
tags: [bootc, podman, automationhub]
---

# Lab 4.5.2 — bootc images (base + app)

**Prereqs:** RHEM up; **build box** with Podman; **AutomationHub** (or internal OCI registry) reachable. **RHEL 9.x** for image content per plan.

## Step 1 — Build host sanity

```bash
podman --version
buildah --version 2>/dev/null || true
```

## Step 2 — Set registry targets

```bash
export REGISTRY="CHANGEME-automationhub.example.com"
export REGISTRY_NAMESPACE="CHANGEME-org"
export BASE_IMG="$REGISTRY/$REGISTRY_NAMESPACE/rhem-edge-base:CHANGEME_TAG"
export APP_IMG="$REGISTRY/$REGISTRY_NAMESPACE/rhem-edge-app:CHANGEME_TAG"
```

Login if required:

```bash
podman login "$REGISTRY"
```

## Step 3 — Build **base** image (enrollment / early binding)

Use Red Hat docs: *Operating system images for Red Hat Edge Manager*, *Building a bootc operating system image for Red Hat Edge Manager*. Keep enrollment config in the image per your EAP early-binding method.

```bash
# Placeholder — replace with your Containerfile / bootc build workflow
# podman build -t "$BASE_IMG" -f Containerfile.base .
# podman push "$BASE_IMG"
```

## Step 4 — Build **app** image (e.g. AWS SSM Agent)

```bash
# podman build -t "$APP_IMG" -f Containerfile.app .
# podman push "$APP_IMG"
```

## Step 5 — Convert to boot media (ISO for USB)

```bash
# Use your documented tool chain (bootc-image-builder, virt-install, etc.)
# Example placeholder:
# podman run --rm ... bootc-image-builder ... --output ./out
ls -la ./out 2>/dev/null || echo "Set out/ path after conversion"
```

## Step 6 — Success check

- [ ] Both images in registry (`podman pull` or registry UI)  
- [ ] Base image converted to **ISO** (or agreed disk format)  
- [ ] DHCP / network assumptions documented for device boot  

**Done.**
