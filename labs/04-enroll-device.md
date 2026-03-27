# Enroll a device

**Goal:** boot a fresh device with the image from Lab 3a, 3b, 3c, or 3d, let it create an enrollment request automatically, and approve that request in Edge Manager.

**Prereqs:** One of the Lab 3 image-building paths is complete.

## Step 1 — Create the CLI context

```bash
export EDGE_MANAGER_HOST="rhem.rhem-eap.lan"
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
- `output/qcow2/disk.qcow2` together with the rendered `user-data.yaml` if you followed the late-binding flow in Lab 3b
- `output/vmdk/` if your virtualization platform imports VMDK images directly
- `output/vmdk/` together with a cloud-init seed ISO if you followed the late-binding VMware flow in Lab 3d

For a VM, create a fresh guest with at least:

- `2` vCPUs
- `4 GiB` RAM
- `20 GiB` disk

For a physical device, write the ISO to boot media and boot from it.

Before first boot, confirm the device can resolve and reach:

- the Edge Manager API hostname
- the Satellite registry hostname

At first boot, the device needs `/etc/flightctl/config.yaml`.

- If you followed Lab 3a, the image already contains that file.
- If you followed Lab 3b, make sure you are booting the artifact together with the late-binding cloud-init user data.

Once that file is present, the device should create an enrollment request automatically on first boot.

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
