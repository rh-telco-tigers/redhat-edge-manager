# Create a fleet and place the device into it

**Goal:** create an Edge Manager `Fleet` that targets the enrolled device and points at the Satellite-hosted bootc image from Lab 3.

**Prereqs:** Lab 4 is complete and the device is online in Edge Manager.

## Step 1 — Create CLI context

```bash
export RHEM_API_URL="https://rhem-prereq-rhel-01.rhem-eap.lan:3443"

flightctl login "$RHEM_API_URL" \
  --username edgemanager-admin \
  --password 'CHANGEME-edgemanager-password' \
  --insecure-skip-tls-verify
```

## Step 2 — Reuse the same image reference from Lab 3

If you followed the manual Lab 3 path, reuse the same Satellite registry path:

```bash
export SATELLITE_IMAGE_REPO="satellite.rhem-eap.lan/id/1/CHANGEME_PRODUCT_ID/device-os"
export OCI_IMAGE_TAG="v1"
export FLEET_IMAGE_REF="${SATELLITE_IMAGE_REPO}:${OCI_IMAGE_TAG}"
```

## Step 3 — Confirm the device labels you want the fleet to match

The approval step in Lab 4 used:

- `site=homelab`
- `fleet=demo`

Check the enrolled device:

```bash
flightctl get devices -o wide
```

## Step 4 — Create the fleet manifest

Create `fleet.yaml`:

```yaml
apiVersion: flightctl.io/v1alpha1
kind: Fleet
metadata:
  name: demo
spec:
  selector:
    matchLabels:
      fleet: "demo"
  template:
    spec:
      os:
        image: "CHANGEME_FLEET_IMAGE_REF"
```

Apply it:

```bash
flightctl apply -f fleet.yaml
```

## Step 5 — Verify the fleet

```bash
flightctl get fleets
flightctl get fleets/demo -o yaml
flightctl get devices -o wide
```

If you want to demonstrate an actual rollout later, build a new image tag such as `v2`, push it to Satellite, update the Fleet manifest to that new tag, and apply it again. Edge Manager remains the rollout and fleet control plane; Satellite is only hosting the bootc image here.

## Step 6 — Use the repo automation for the same flow

Create or update the demo fleet:

```bash
make fleet-apply
```

Run the whole Labs 3 to 5 automation path after `make up`:

```bash
make device-demo
```

That sequence:

- builds and pushes the bootc image to Satellite
- creates the demo device VM
- waits for enrollment and approves it
- applies the demo fleet
