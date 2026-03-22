# Troubleshooting

Use this page when the labs or automation get far enough to show a real symptom, but something is still not working as expected.

## Device shows `Unsupported` for device identity or TPM

Example symptoms in the Edge Manager UI or `Device` YAML:

- `TPM not present or not enabled on this device`
- `Device identity - Unsupported`
- `TPM - Unsupported`

### What it means

The device is still enrolled and manageable, but Edge Manager cannot use TPM-backed identity or integrity features on that device.

This is common in lab VMs because the VM was created without a TPM device.

### Is it safe to ignore?

For a basic demo, yes.

If your goal is to demonstrate device integrity, device identity, or TPM-backed attestation, you need to fix it.

### How to confirm on the device

```bash
ls -l /dev/tpm*
sudo dmesg | grep -i tpm | tail -20
```

If no TPM device exists, you usually will not see `/dev/tpm0` or `/dev/tpmrm0`.

### How to fix it manually

On a physical device:

1. Reboot into firmware or BIOS settings.
2. Enable TPM 2.0.
3. If the system uses firmware TPM, enable Intel PTT or AMD fTPM.
4. Boot the system again and confirm the TPM device exists in the OS.

On a virtual machine:

1. Power off the VM.
2. Add a TPM 2.0 device in your virtualization platform.
3. Make sure the VM uses UEFI firmware.
4. Boot the VM again.
5. Confirm `/dev/tpm0` or `/dev/tpmrm0` exists.

For Proxmox:

1. Power off the VM.
2. Open the VM in Proxmox.
3. Go to **Hardware**.
4. Click **Add** → **TPM State**.
5. Use TPM version `2.0`.
6. Confirm the VM also uses:
   - BIOS: `OVMF (UEFI)`
   - Machine: `q35`
7. Start the VM again.

If the VM was originally built without TPM and the status still stays `Unsupported`, the cleanest fix is often to delete and recreate the device VM with TPM enabled from the start.

## Device shows `Out-of-date`

Example symptom in the UI:

- `Out-of-date`
- `Device has not yet been scheduled for update to the fleet's latest spec`

### What it means

The device is enrolled, but Edge Manager has not yet queued that device to move to the latest fleet-rendered spec.

In most cases, this means one of these:

- the device is not matched by the fleet selector
- the device does not have a fleet owner yet
- the fleet changed, but the controller has not reconciled the device yet
- the device is disconnected, paused, or still finishing earlier work
- the device labels do not match the fleet selector

### How to confirm

Check the device and fleet state:

```bash
flightctl get devices -o wide
flightctl get device CHANGEME_DEVICE -o yaml
flightctl get fleets -o yaml
```

Focus on these fields:

- `metadata.owner`
- `metadata.labels`
- `status.updated.status`
- `status.summary.status`
- `spec.selector.matchLabels` on the fleet

### How to fix it manually

1. Confirm the device labels match the fleet selector.

Example:

- device label: `fleet=demo`
- fleet selector: `fleet=demo`

2. Confirm the device is actually owned by the expected fleet.

If not, reapply the fleet manifest:

```bash
flightctl apply -f fleet.yaml
```

3. Confirm the device is online.

If `status.summary.status` is not `Online`, fix connectivity or agent issues first.

4. If you just approved enrollment, wait a short time and check again.

There can be a short delay between enrollment approval, fleet matching, and update scheduling.

5. If the labels are wrong, correct them and then recheck the fleet.

6. If needed, reapply the fleet manifest after fixing labels:

```bash
flightctl apply -f fleet.yaml
flightctl get device CHANGEME_DEVICE -o yaml
```

When the device is successfully scheduled and reconciled, `status.updated.status` should move toward `UpToDate`.

## Browser shows `404 page not found` on `https://<host>:3443/`

### What it means

Port `3443` is the Edge Manager API endpoint used by the `flightctl` CLI. It is not the normal browser UI endpoint.

### How to fix it manually

Use:

- Browser UI: `https://<host>/`
- CLI or API: `https://<host>:3443`

Example:

```bash
flightctl login "https://edge-manager.example.com:3443"
```

## Login succeeds but the UI shows `Restricted Access`

### What it means

Authentication worked, but authorization did not. The user signed in, but Edge Manager did not receive the roles or permissions it needs.

### How to fix it manually

If you use Keycloak:

1. Confirm the user has the `flightctl-admin` realm role.
2. Confirm the user also has the built-in `offline_access` role.
3. Confirm the `flightctl-client` client exposes `realm_access.roles` in `userinfo`.
4. Log out fully and start a fresh browser session.

If you use AAP:

1. Confirm the user has the organization access or roles required by your AAP policy.
2. Confirm Edge Manager is pointed at the correct AAP URL.
3. Confirm the OAuth application or token configuration is valid.
4. Log out fully and start a fresh browser session.

## Keycloak login fails with `Invalid parameter: redirect_uri`

### What it means

The Keycloak client does not allow the exact callback URL that Edge Manager is using.

### How to fix it manually

Add the Edge Manager callback URLs to the Keycloak client.

Typical values:

- `https://edge-manager.example.com/*`
- `https://edge-manager.example.com:443/*`
- `http://localhost:8080/*`

Also confirm the browser URL you are using matches the hostname configured in Edge Manager.

## Keycloak login fails with `invalid_scope`

### What it means

The Keycloak client is missing one or more scopes that Edge Manager requests during login.

### How to fix it manually

Confirm the client allows these scopes:

- `openid`
- `profile`
- `email`
- `roles`
- `offline_access`

If the user can log in but later fails during token exchange, also confirm the user has the built-in `offline_access` role.

## macOS does not resolve the demo domain even though `/etc/resolv.conf` looks correct

### What it means

On macOS, most applications do not use `/etc/resolv.conf` directly. The system resolver uses `scutil` and optional per-domain resolver files.

### How to fix it manually

Create a resolver file for the demo domain:

```bash
sudo mkdir -p /etc/resolver
printf 'nameserver 192.168.4.30\n' | sudo tee /etc/resolver/rhem-eap.lan >/dev/null
sudo dscacheutil -flushcache
sudo killall -HUP mDNSResponder
```

Then verify:

```bash
scutil --dns | grep -A5 'rhem-eap.lan'
dscacheutil -q host -a name rhem.rhem-eap.lan
```

## `podman: command not found` during Edge Manager install

### What it means

The host does not have Podman installed yet, but the install flow expects it for `registry.redhat.io` login and container-based components.

### How to fix it manually

Install Podman before the registry login step:

```bash
sudo dnf install -y podman
podman --version
sudo podman login registry.redhat.io
```

## Collect support data

If you are past the first-fix stage and still need to investigate:

1. Save the current `Device`, `Fleet`, and relevant host configuration as YAML.
2. Capture `journalctl` output from the RHEM host or device.
3. Follow [labs/07-monitoring-support.md](labs/07-monitoring-support.md) for the current monitoring and must-gather notes.

Add new entries to this page as you encounter them.
