# Publish images through the Satellite registry

Use this note when a manual lab needs a private OCI registry for:

- bootc operating system images
- application runtime images
- Edge Manager application package images

This is the default shared registry path for the current manual labs.

## What you get from this note

When you finish these steps, you should have:

- `SATELLITE_ORG_ID`
- `SATELLITE_PRODUCT_ID`
- a working image path such as `OCI_IMAGE_REPO`
- `satellite-ca.crt` copied to your build host
- successful `podman login` sessions for both:
  - `registry.redhat.io`
  - `${SATELLITE_HOST}`

## Step 1 — Set the Satellite hostname

```bash
export SATELLITE_HOST="satellite.rhem-eap.lan"
```

## Step 2 — Create or reuse the product that will hold your images

SSH to the Satellite host:

```bash
ssh <admin_user>@${SATELLITE_HOST}
```

Find the organization ID:

```bash
sudo hammer --output csv organization list
```

Create the `bootc` product if it does not already exist:

```bash
sudo hammer product create \
  --organization-id CHANGEME_ORG_ID \
  --name bootc \
  --label bootc
```

Find the product ID for `bootc`:

```bash
sudo hammer --output csv product list --organization-id CHANGEME_ORG_ID
```

For a lab or demo environment, allow unauthenticated pull from `Library`:

```bash
sudo hammer lifecycle-environment update \
  --organization-id CHANGEME_ORG_ID \
  --name Library \
  --registry-unauthenticated-pull true
```

Export the IDs for later steps:

```bash
export SATELLITE_ORG_ID="CHANGEME_ORG_ID"
export SATELLITE_PRODUCT_ID="CHANGEME_PRODUCT_ID"
```

## Step 3 — Define the image paths you will use

For the bootc image labs:

```bash
export OCI_IMAGE_REPO="${SATELLITE_HOST}/id/${SATELLITE_ORG_ID}/${SATELLITE_PRODUCT_ID}/device-os"
```

For the application lab:

```bash
export DEMO_RUNTIME_IMAGE_REPO="${SATELLITE_HOST}/id/${SATELLITE_ORG_ID}/${SATELLITE_PRODUCT_ID}/hello-web-runtime"
export DEMO_PACKAGE_IMAGE_REPO="${SATELLITE_HOST}/id/${SATELLITE_ORG_ID}/${SATELLITE_PRODUCT_ID}/hello-web-package"
```

## Step 4 — Trust the Satellite CA on the build host

Run these commands on the build host that will execute `podman build` and `podman push`:

```bash
curl -k "https://${SATELLITE_HOST}/pub/katello-server-ca.crt" \
  -o satellite-ca.crt
```

Install that CA for container pulls and pushes:

```bash
sudo mkdir -p /etc/containers/certs.d/${SATELLITE_HOST}
sudo cp satellite-ca.crt /etc/containers/certs.d/${SATELLITE_HOST}/ca.crt
sudo cp satellite-ca.crt /etc/pki/ca-trust/source/anchors/${SATELLITE_HOST}.crt
sudo update-ca-trust
```

Keep `satellite-ca.crt` in your working directory if the manual lab later tells you to place it in a bootc build context or a late-binding cloud-init payload.

## Step 5 — Log in to the registries

```bash
sudo podman login registry.redhat.io

sudo podman login "${SATELLITE_HOST}" \
  --username admin \
  --password 'CHANGEME-satellite-admin-password'
```

After this point, return to the lab you were following and use the exported image paths there.

## Notes

- The current early-binding bootc sources in this repo expect `satellite-ca.crt` in the build context because they bake trust for the private Satellite registry into the image.
- The late-binding bootc flows still need `satellite-ca.crt` later when they render the provisioning-time cloud-init payload.
- The application lab also reuses the same Satellite product and image path pattern.
