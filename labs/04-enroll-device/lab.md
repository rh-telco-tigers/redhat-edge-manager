# Enroll a device

**Goal:** boot a fresh device with the image from Lab 3, let it create an enrollment request automatically, and approve that request in Edge Manager.

**Prereqs:** Lab 3 is complete.

## Step 1 — Create the CLI context

```bash
export EDGE_MANAGER_HOST="edge-manager.example.com"
export EDGE_MANAGER_API_URL="https://${EDGE_MANAGER_HOST}:3443"

flightctl login "${EDGE_MANAGER_API_URL}" \
  --username edgemanager-admin \
  --password 'CHANGEME-edgemanager-password' \
  --insecure-skip-tls-verify
```

## Step 2 — Boot a fresh device

Use the installer artifact that matches your target platform:

- `output/bootiso/install.iso` if you are booting from ISO media
- `output/qcow2/disk.qcow2` if your virtualization platform imports qcow2 images directly

For a VM, create a fresh guest with at least:

- `2` vCPUs
- `4 GiB` RAM
- `20 GiB` disk

For a physical device, write the ISO to boot media and boot from it.

Before first boot, confirm the device can resolve and reach:

- the Edge Manager API hostname
- the Satellite registry hostname

Because the image already includes `/etc/flightctl/config.yaml`, the device should create an enrollment request automatically on first boot.

## Step 3 — List pending enrollment requests

```bash
flightctl get enrollmentrequests \
  --field-selector="status.approval.approved != true"
```

You should see a pending request from the new device.

## Step 4 — Approve the enrollment request

Approve the request and assign the labels that you want to use in the next lab:

```bash
flightctl approve enrollmentrequest/CHANGEME_REQUEST_NAME \
  -l site=homelab \
  -l fleet=demo
```

You can choose different label values if they better match your environment. The important point is to use labels that you can later target from a `Fleet`.

## Step 5 — Verify the device is online

```bash
flightctl get devices -o wide
```

The device should now show as enrolled and online.

At this point the device is ready for the fleet workflow in Lab 5.
