# Build an early-binding bootc image and publish it through Satellite

**Goal:** build the device operating system image, publish it to Satellite, and generate the bootable installer artifact with the Edge Manager enrollment configuration already included.

**Prereqs:** Labs 1 and 2 are complete. You have:

- a working Edge Manager host
- a working Satellite host
- shell access to both hosts
- credentials for `registry.redhat.io`
- credentials for the Satellite registry

## Step 1 — Set the hostnames you will use in this lab

```bash
export EDGE_MANAGER_HOST="rhem.rhem-eap.lan"
export SATELLITE_HOST="satellite.rhem-eap.lan"
export EDGE_MANAGER_API_URL="https://${EDGE_MANAGER_HOST}:3443"
export OCI_IMAGE_TAG="v1"
```

Use the API certificate hostname for `EDGE_MANAGER_HOST`.

## Step 2 — Prepare the registry and build host

Follow the shared Satellite note:

- [`../extras/publishing-images-to-satellite-registry.md`](../extras/publishing-images-to-satellite-registry.md)

When you return to this lab, you should already have:

- `SATELLITE_ORG_ID`
- `SATELLITE_PRODUCT_ID`
- `OCI_IMAGE_REPO`
- `satellite-ca.crt`
- successful `podman login` to both `registry.redhat.io` and `${SATELLITE_HOST}`

If you want to review the public-registry alternative as well, see:

- [`../extras/publishing-images-to-quay-registry.md`](../extras/publishing-images-to-quay-registry.md)

## Step 3 — Request the early-binding enrollment configuration

SSH to the Edge Manager host:

```bash
ssh <admin_user>@${EDGE_MANAGER_HOST}
```

Log in with `flightctl` and request the embedded enrollment configuration:

```bash
flightctl login "${EDGE_MANAGER_API_URL}" \
  --username edgemanager-admin \
  --password 'CHANGEME-edgemanager-password' \
  --insecure-skip-tls-verify

flightctl certificate request \
  --signer enrollment \
  --expiration 365d \
  --output embedded > config.yaml
```

Confirm that `config.yaml` points to the API certificate hostname:

```yaml
enrollment-service:
  enrollment-ui-endpoint: https://rhem.rhem-eap.lan:443
  service:
    server: https://rhem.rhem-eap.lan:7443/
```

If your generated file shows a different host that is not covered by the Edge Manager API certificate, replace those values before building the image.

## Step 4 — Build the bootc image

This repo keeps the reusable early-binding build source in [`../bootc/earlybinding/`](../bootc/earlybinding/README.md).

Create a working directory on the build host:

```bash
mkdir -p ~/device-os
cd ~/device-os
```

Use these files from [`../bootc/earlybinding/`](../bootc/earlybinding/README.md):

- [`../bootc/earlybinding/Containerfile`](../bootc/earlybinding/Containerfile)
- [`../bootc/earlybinding/installer.toml`](../bootc/earlybinding/installer.toml)
- [`../bootc/earlybinding/rhem-demo-hosts.sh`](../bootc/earlybinding/rhem-demo-hosts.sh)
- [`../bootc/earlybinding/rhem-demo-hosts.service`](../bootc/earlybinding/rhem-demo-hosts.service)

Copy those files into the build directory. If your hostnames differ from the defaults in this repo, edit the obvious lines in `Containerfile` and `rhem-demo-hosts.sh`. Place these generated files in the same build context:

- `config.yaml`
- `satellite-ca.crt` from the shared Satellite registry note
- `demo-authorized-key.pub`

Build and push the image:

```bash
sudo podman build -t "${OCI_IMAGE_REPO}:${OCI_IMAGE_TAG}" .
sudo podman push "${OCI_IMAGE_REPO}:${OCI_IMAGE_TAG}"
```

Tag the same image into local container storage for `bootc-image-builder`:

```bash
sudo podman tag \
  "${OCI_IMAGE_REPO}:${OCI_IMAGE_TAG}" \
  "localhost/device-os:${OCI_IMAGE_TAG}"
```

## Step 5 — Generate the bootable installer artifact

Use `bootc-image-builder` against the locally tagged image. This avoids private-registry pull issues during artifact generation.

Create the output directory:

```bash
mkdir -p output
```

If you want ISO media for a VM console boot or a physical-device boot:

```bash
sudo podman run --rm -it --privileged --pull=newer \
  --security-opt label=type:unconfined_t \
  -v "${PWD}/output":/output \
  -v /var/lib/containers/storage:/var/lib/containers/storage \
  -v "${PWD}/installer.toml":/config.toml:ro \
  registry.redhat.io/rhel9/bootc-image-builder:latest \
  --type iso \
  --local \
  --config /config.toml \
  "localhost/device-os:${OCI_IMAGE_TAG}"
```

ISO artifact:

```text
output/bootiso/install.iso
```

If your virtualization platform can import a qcow2 disk image directly:

```bash
sudo podman run --rm -it --privileged --pull=newer \
  --security-opt label=type:unconfined_t \
  -v "${PWD}/output":/output \
  -v /var/lib/containers/storage:/var/lib/containers/storage \
  registry.redhat.io/rhel9/bootc-image-builder:latest \
  --type qcow2 \
  --local \
  "localhost/device-os:${OCI_IMAGE_TAG}"
```

QCOW2 artifact:

```text
output/qcow2/disk.qcow2
```

## Step 6 — Prepare for the next lab

Keep the installer artifact that matches your target platform:

- `output/bootiso/install.iso` for ISO-based boot
- `output/qcow2/disk.qcow2` for qcow2-based VM import

You will use that artifact to boot a fresh device in Lab 4.
