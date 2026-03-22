# Security and compliance review

**Goal:** verify access control, TLS, trusted image sources, and patch posture for the Edge Manager environment and the enrolled device.

**Prereqs:** Labs 1 to 6 are complete. At least one device is online in Edge Manager.

## Step 1 — Create the working context

```bash
export EDGE_MANAGER_HOST="edge-manager.example.com"
export EDGE_MANAGER_API_URL="https://${EDGE_MANAGER_HOST}:3443"
export SATELLITE_HOST="satellite.example.com"
export KEYCLOAK_HOST="keycloak.example.com"
export DEVICE_NAME="CHANGEME_DEVICE_NAME"
export DEVICE_HOST="CHANGEME_DEVICE_HOST"

flightctl login "${EDGE_MANAGER_API_URL}" \
  --username edgemanager-admin \
  --password 'CHANGEME-edgemanager-password' \
  --insecure-skip-tls-verify
```

## Step 2 — Review who has administrative access

Confirm that the CLI session can read Edge Manager resources:

```bash
flightctl get devices
flightctl get fleets
```

Then review the identity source that backs your Edge Manager login:

- If you use Keycloak, confirm only intended administrators have the `flightctl-admin` realm role.
- If you use AAP, confirm only intended administrators have the roles or organization access required by your AAP policy.
- If you use the local PAM issuer, confirm only intended administrators are in the `flightctl-admin` group.
- If you have a non-admin user available, sign in with that user and confirm it cannot modify fleets, repositories, or devices.

## Step 3 — Verify TLS and endpoint identity

Check the Edge Manager web and API endpoints:

```bash
curl -skI "https://${EDGE_MANAGER_HOST}/" | head -5
curl -skI "https://${EDGE_MANAGER_HOST}:3443/" | head -5

openssl s_client -connect "${EDGE_MANAGER_HOST}:3443" -servername "${EDGE_MANAGER_HOST}" </dev/null 2>/dev/null \
  | openssl x509 -noout -subject -issuer -dates
```

Check the supporting services:

```bash
openssl s_client -connect "${SATELLITE_HOST}:443" -servername "${SATELLITE_HOST}" </dev/null 2>/dev/null \
  | openssl x509 -noout -subject -issuer -dates

openssl s_client -connect "${KEYCLOAK_HOST}:443" -servername "${KEYCLOAK_HOST}" </dev/null 2>/dev/null \
  | openssl x509 -noout -subject -issuer -dates
```

Confirm the certificate hostnames, issuers, and expiration dates match what you expect.

## Step 4 — Verify approved OS and application image sources

Review the fleet definition and device status:

```bash
flightctl get fleets/demo -o yaml
flightctl get device "${DEVICE_NAME}" -o yaml
```

Confirm these values point only to approved registries:

- `spec.template.spec.os.image`
- `spec.template.spec.applications[*].image`
- `status.os.image`

If you can SSH to the device, confirm the running application image and current booted image:

```bash
ssh <device_user>@${DEVICE_HOST}

sudo bootc status
sudo podman ps --format 'table {{.Names}}\t{{.Image}}\t{{.Status}}'
```

## Step 5 — Review patch and package state

On the Edge Manager host:

```bash
sudo subscription-manager status
sudo dnf updateinfo summary
rpm -q flightctl-services flightctl-cli
```

On the managed device:

```bash
ssh <device_user>@${DEVICE_HOST}

sudo bootc status
sudo journalctl -u flightctl-agent -n 50
```

Confirm the device is on the expected image and that the agent is connected without repeated auth or certificate errors.

## Step 6 — Collect evidence for the review

Save the current configuration and status:

```bash
mkdir -p security-review

flightctl get fleets/demo -o yaml > security-review/fleet-demo.yaml
flightctl get device "${DEVICE_NAME}" -o yaml > security-review/device.yaml
openssl s_client -connect "${EDGE_MANAGER_HOST}:3443" -servername "${EDGE_MANAGER_HOST}" </dev/null 2>/dev/null \
  | openssl x509 -noout -subject -issuer -dates > security-review/edge-manager-api-cert.txt
```

Add any screenshots, exported reports, or policy results that your team requires.
