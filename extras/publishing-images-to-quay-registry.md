# Publish images through Quay

Use this note when you want a public OCI registry for manual labs instead of the private Satellite registry.

This is especially useful for demos where the VM or device is running outside your local network and cannot easily reach your Satellite host.

## What you get from this note

When you finish these steps, you should have:

- a Quay namespace
- one or more Quay repositories
- successful `podman login quay.io`
- image paths for bootc or application images

## Step 1 — Create the Quay repositories

In Quay, create the repositories you need. For example:

- `device-os`
- `hello-web-runtime`
- `hello-web-package`

For quick demos, public repositories are usually simpler than private ones.

## Step 2 — Set the Quay image paths

```bash
export QUAY_HOST="quay.io"
export QUAY_NAMESPACE="CHANGEME_NAMESPACE"

export OCI_IMAGE_REPO="${QUAY_HOST}/${QUAY_NAMESPACE}/device-os"
export DEMO_RUNTIME_IMAGE_REPO="${QUAY_HOST}/${QUAY_NAMESPACE}/hello-web-runtime"
export DEMO_PACKAGE_IMAGE_REPO="${QUAY_HOST}/${QUAY_NAMESPACE}/hello-web-package"
```

## Step 3 — Log in to Quay

```bash
sudo podman login quay.io
```

Use your Quay username and password, or a robot account token if that is how your organization manages pushes.

## Step 4 — Build and push the images

Once the manual lab tells you to run `podman build`, use the Quay image path instead of the Satellite path.

Example for a bootc image:

```bash
sudo podman build -t "${OCI_IMAGE_REPO}:v1" .
sudo podman push "${OCI_IMAGE_REPO}:v1"
```

Example for the demo application:

```bash
sudo podman build -t "${DEMO_RUNTIME_IMAGE_REPO}:v1" -f runtime/Containerfile runtime
sudo podman push "${DEMO_RUNTIME_IMAGE_REPO}:v1"
```

## Notes

- Quay uses public CA-signed HTTPS, so you do not need `satellite-ca.crt` or extra local CA trust steps for the registry itself.
- This note only covers the registry side.
- The VMware VMDK early-binding and late-binding labs in this repo now point to Quay directly.
