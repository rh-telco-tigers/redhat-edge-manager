# Enroll (onboard) a device

**Goal:** boot the Edge Manager image from Lab 3, let it create an enrollment request automatically, and approve that request in Edge Manager.

**Prereqs:** Lab 3 is complete.

Both the manual path and the automated Proxmox path use the same installer ISO:
`automation/artifacts/bootc/rhem-prereq-rhel-01/install.iso`

## Step 1 — Create CLI context

```bash
export RHEM_API_URL="https://rhem-prereq-rhel-01.rhem-eap.lan:3443"

flightctl login "$RHEM_API_URL" \
  --username edgemanager-admin \
  --password 'CHANGEME-edgemanager-password' \
  --insecure-skip-tls-verify
```

## Step 2 — Manual device path: boot a fresh device from the installer ISO

You have two manual options:

- Physical or laptop-like demo device:
  write `install.iso` to USB and boot the device from it.
- Proxmox manual demo:
  create a fresh VM with at least `2 vCPU`, `4 GiB RAM`, and a `20 GiB` disk, upload `install.iso`, attach it as virtual media, and boot from it.

For the first manual Proxmox boot:

- use a brand-new empty disk
- keep the NIC on the same network as the management stack
- boot from the ISO first so the unattended install can lay the image down
- after installation completes, eject the ISO or switch boot order back to the disk so it does not loop back into the installer

Because the image already includes `/etc/flightctl/config.yaml`, the installed device should create an enrollment request on first boot after installation completes.

## Step 3 — Automated Proxmox device path

If you want the repo to create the demo device VM for you, use the same ISO-backed flow:

```bash
make device-vm-up
```

That uploads `install.iso` to Proxmox, creates one fresh VM with a blank disk, and boots it through the unattended installer.

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
