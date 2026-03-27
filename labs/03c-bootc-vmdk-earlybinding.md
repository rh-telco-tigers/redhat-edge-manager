# Build an early-binding bootc VMDK for VMware vSphere and enroll the VM

**Goal:** build a bootc operating system image for VMware vSphere, generate a `vmdk` disk artifact with the Edge Manager enrollment configuration already included, create a VM in vSphere, and verify that it appears in Edge Manager after approval.

**Prereqs:** Labs 1 and 2 are complete. You have:

- a working Edge Manager host
- a build host that can run `podman`
- access to a VMware vSphere environment
- credentials for `registry.redhat.io`
- access to a Quay repository you can push to

## Step 1 — Set the hostnames you will use in this lab

```bash
export EDGE_MANAGER_HOST="rhem.rhem-eap.lan"
export EDGE_MANAGER_API_URL="https://${EDGE_MANAGER_HOST}:3443"
export OCI_IMAGE_TAG="v1"
```

Use the API certificate hostname for `EDGE_MANAGER_HOST`.

## Step 2 — Prepare the registry and build host

Follow the shared Quay note:

- [`../extras/publishing-images-to-quay-registry.md`](../extras/publishing-images-to-quay-registry.md)

When you return to this lab, you should already have:

- `OCI_IMAGE_REPO`
- successful `podman login` to both `registry.redhat.io` and `quay.io`

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

## Step 4 — Prepare the VMware-targeted build context

This repo keeps the reusable VMware early-binding source in [`../bootc/vmdk-earlybinding/`](../bootc/vmdk-earlybinding/README.md).

Create a working directory on the build host:

```bash
mkdir -p ~/device-os-vmdk
cd ~/device-os-vmdk
```

Copy these files from [`../bootc/vmdk-earlybinding/`](../bootc/vmdk-earlybinding/README.md):

- [`../bootc/vmdk-earlybinding/Containerfile`](../bootc/vmdk-earlybinding/Containerfile)
- [`../bootc/vmdk-earlybinding/rhem-demo-hosts.sh`](../bootc/vmdk-earlybinding/rhem-demo-hosts.sh)
- [`../bootc/vmdk-earlybinding/rhem-demo-hosts.service`](../bootc/vmdk-earlybinding/rhem-demo-hosts.service)

Place these generated files in the same build context:

- `config.yaml`
- `demo-authorized-key.pub`

If your hostnames differ from the defaults in this repo, edit the obvious lines in `Containerfile` and `rhem-demo-hosts.sh`.

## Step 5 — Build and push the bootc image

```bash
sudo podman build -t "${OCI_IMAGE_REPO}:${OCI_IMAGE_TAG}" .
sudo podman push "${OCI_IMAGE_REPO}:${OCI_IMAGE_TAG}"

sudo podman tag \
  "${OCI_IMAGE_REPO}:${OCI_IMAGE_TAG}" \
  "localhost/device-os:${OCI_IMAGE_TAG}"
```

## Step 6 — Generate the VMDK artifact

Create the output directory:

```bash
mkdir -p output
```

Build the VMDK disk image:

```bash
sudo podman run --rm -it --privileged --pull=newer \
  --security-opt label=type:unconfined_t \
  -v "${PWD}/output":/output \
  -v /var/lib/containers/storage:/var/lib/containers/storage \
  registry.redhat.io/rhel9/bootc-image-builder:latest \
  --type vmdk \
  --local \
  "localhost/device-os:${OCI_IMAGE_TAG}"
```

VMDK artifact:

```text
output/vmdk/disk.vmdk
```

Upload the contents of `output/vmdk/` to a vSphere datastore and keep those files together in the same datastore folder.

## Step 7 — Create the VM in vSphere

In the vSphere Client:

1. Upload the VMDK output directory to a datastore folder.
2. Create a new virtual machine.
3. Set:
   - Guest OS family: `Linux`
   - Guest OS version: `Red Hat Enterprise Linux 9 (64-bit)`
4. Allocate at least:
   - `2` vCPUs
   - `4 GiB` RAM
5. Remove the default hard disk.
6. Add an existing hard disk and select the uploaded `disk.vmdk`.
7. Use a network that can reach:
   - the Edge Manager API hostname
   - `quay.io`
8. Power on the VM.

Because this is the early-binding flow, no extra cloud-init or seed ISO is required.

## Step 8 — Approve the enrollment request and verify the device

On the Edge Manager host:

```bash
flightctl get enrollmentrequests \
  --field-selector="status.approval.approved != true"
```

Approve the request:

```bash
flightctl approve enrollmentrequest/CHANGEME_REQUEST_NAME \
  -l site=homelab \
  -l fleet=demo
```

Verify the device is online:

```bash
flightctl get devices -o wide
```

At this point the vSphere VM should show as enrolled and online in Edge Manager, and you can continue with Lab 5.
