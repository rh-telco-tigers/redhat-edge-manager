# Create a fleet and place the device into it

**Goal:** create an Edge Manager `Fleet` that targets the enrolled device and points at the bootc image that you published in Lab 3.

**Prereqs:** Lab 4 is complete and the device is online in Edge Manager.

## Step 1 — Create the CLI context

```bash
export EDGE_MANAGER_HOST="rhem.rhem-eap.lan"
export EDGE_MANAGER_API_URL="https://${EDGE_MANAGER_HOST}:3443"

flightctl login "${EDGE_MANAGER_API_URL}" \
  --username edgemanager-admin \
  --password 'CHANGEME-edgemanager-password' \
  --insecure-skip-tls-verify
```

## Step 2 — Reuse the image reference from Lab 3

```bash
export SATELLITE_HOST="satellite.rhem-eap.lan"
export SATELLITE_ORG_ID="CHANGEME_ORG_ID"
export SATELLITE_PRODUCT_ID="CHANGEME_PRODUCT_ID"
export OCI_IMAGE_TAG="v1"
export FLEET_IMAGE_REF="${SATELLITE_HOST}/id/${SATELLITE_ORG_ID}/${SATELLITE_PRODUCT_ID}/device-os:${OCI_IMAGE_TAG}"
```

## Step 3 — Confirm the device labels you want the fleet to match

If you used the labels from Lab 4, the device should already have:

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

Replace `CHANGEME_FLEET_IMAGE_REF` with the full value of `${FLEET_IMAGE_REF}`.

Apply the manifest:

```bash
flightctl apply -f fleet.yaml
```

## Step 5 — Verify the fleet

```bash
flightctl get fleets
flightctl get fleets/demo -o yaml
flightctl get devices -o wide
```

The device should now be owned by `Fleet/demo`.

If you publish a new OS image later, update the image tag in `fleet.yaml` and apply the manifest again.
