# Enroll (onboard) a device

**Goal:** boot the Edge Manager image from Lab 3, let it create an enrollment request automatically, and approve that request in Edge Manager.

**Prereqs:** Lab 3 is complete.

For the Proxmox demo path, both the manual path and the automated path use the same bootable disk artifact:
`automation/artifacts/bootc/rhem-prereq-rhel-01/disk.qcow2`

## Step 1 — Create CLI context

```bash
export RHEM_API_URL="https://rhem.rhem-eap.lan:3443"

flightctl login "$RHEM_API_URL" \
  --username edgemanager-admin \
  --password 'CHANGEME-edgemanager-password' \
  --insecure-skip-tls-verify
```

## Step 2 — Manual device path

You have two manual options:

- Physical or laptop-like demo device:
  build an ISO separately if you need USB-style boot media.
- Proxmox manual demo:
  use the bootable `disk.qcow2` artifact as the VM disk image.

For the Proxmox manual VM path:

- build and fetch the qcow2 first:
  `make bootc-build`
- use `automation/artifacts/bootc/rhem-prereq-rhel-01/disk.qcow2`
- create a fresh VM with at least `2 vCPU`, `4 GiB RAM`, and a `20 GiB` disk target
- import the qcow2 as the primary disk and boot the VM from that imported disk
- keep the NIC on the same network as the management stack

Because the image already includes `/etc/flightctl/config.yaml`, the installed device should create an enrollment request on first boot after installation completes.

For the repo-managed demo image, `cloud-user` also has the local `~/.ssh/redhat-edge-manager-demo.pub` key, so you can SSH to the device if you need to inspect it after boot.

## Step 3 — Automated Proxmox device path

If you want the repo to create the demo device VM for you, use the qcow2-backed flow:

```bash
make device-vm-up
```

That uploads `disk.qcow2` to Proxmox, creates one fresh VM, imports the bootable disk image, and boots it directly.

For the standalone VM path, make sure the qcow2 exists first:

```bash
make bootc-build
```

Override the defaults if needed:

```bash
VM_ID=151 VM_NAME=rhem-device-02 make device-vm-up
```

## Step 4 — List pending enrollment requests

```bash
flightctl get enrollmentrequests \
  --field-selector="status.approval.approved != true"
```

You should see a pending request from the new device.

## Step 5 — Approve the enrollment request

Approve one request manually:

```bash
flightctl approve enrollmentrequest/CHANGEME_REQUEST_NAME \
  -l site=homelab \
  -l fleet=demo
```

Or use the repo automation:

```bash
make approve-enrollment
```

If you want the repo to wait until a request appears first:

```bash
WAIT_FOR_PENDING=true make approve-enrollment
```

The default labels are defined in `automation/ansible/group_vars/all.yml.example`.

## Step 6 — Verify the device is online

```bash
flightctl get devices -o wide
```

At this point the device is enrolled and ready for the Fleet workflow in Lab 5.
