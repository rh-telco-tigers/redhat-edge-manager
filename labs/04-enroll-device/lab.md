# Enroll (onboard) device

**Goal:** boot the ISO from Lab 3, let the device create an enrollment request, then approve it in Edge Manager.

**Prereqs:** Lab 3 is complete. You have a bootable ISO with the embedded `config.yaml`, and the device can reach Edge Manager on `HTTPS/443`.

## Step 1 — CLI context

```bash
export RHEM_API_URL="https://rhem-prereq-rhel-01.rhem-eap.lan:3443"
flightctl login "$RHEM_API_URL" \
  --username edgemanager-admin \
  --password 'CHANGEME-edgemanager-password' \
  --insecure-skip-tls-verify
```

## Step 2 — Boot the device from the ISO

- If you used the automation path in Lab 3, the ISO is here:

```text
automation/artifacts/bootc/rhem-prereq-rhel-01/install.iso
```

- Write that ISO to USB or attach it as virtual media.
- Boot the device.
- Confirm the device gets network connectivity and can reach `rhem-prereq-rhel-01.rhem-eap.lan`.

Because the image already includes `/etc/flightctl/config.yaml`, the agent should create an enrollment request automatically on first boot.

## Step 3 — List pending enrollment

```bash
flightctl get enrollmentrequests \
  --field-selector="status.approval.approved != true"
```

You should see a pending request for the newly booted device.

## Step 4 — Approve the enrollment request

Approve it manually:

```bash
flightctl approve enrollmentrequest/CHANGEME_REQUEST_NAME \
  -l site=homelab \
  -l fleet=demo
```

Or approve everything that is pending by using the repo automation:

```bash
make approve-enrollment
```

That automation uses the same `flightctl` CLI on the RHEM host and applies the default labels from `automation/ansible/group_vars/all.yml.example`.

## Step 5 — Verify the device is registered

```bash
flightctl get devices -o wide
```

At this point the device is onboarded and ready for the next labs.
