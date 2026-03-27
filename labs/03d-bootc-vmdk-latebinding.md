# Build a late-binding bootc VMDK for VMware vSphere and enroll the VM

**Goal:** build a bootc operating system image for VMware vSphere, generate a clean `vmdk` disk artifact, inject the enrollment configuration at provisioning time, create a VM in vSphere, and verify that it appears in Edge Manager after approval.

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

## Step 3 — Prepare the VMware-targeted build context

This repo keeps the reusable VMware late-binding source in [`../bootc/vmdk-latebinding/`](../bootc/vmdk-latebinding/README.md).

Create a working directory on the build host:

```bash
mkdir -p ~/device-os-vmdk
cd ~/device-os-vmdk
```

Copy these files from [`../bootc/vmdk-latebinding/`](../bootc/vmdk-latebinding/README.md):

- [`../bootc/vmdk-latebinding/Containerfile`](../bootc/vmdk-latebinding/Containerfile)
- [`../bootc/vmdk-latebinding/rhem-demo-hosts.sh`](../bootc/vmdk-latebinding/rhem-demo-hosts.sh)
- [`../bootc/vmdk-latebinding/rhem-demo-hosts.service`](../bootc/vmdk-latebinding/rhem-demo-hosts.service)
- [`../bootc/vmdk-latebinding/user-data.yaml`](../bootc/vmdk-latebinding/user-data.yaml)

Place this generated file in the same build context:

- `demo-authorized-key.pub`

If your hostnames differ from the defaults in this repo, edit the obvious lines in `Containerfile` and `rhem-demo-hosts.sh`.

## Step 4 — Build and push the bootc image

```bash
sudo podman build -t "${OCI_IMAGE_REPO}:${OCI_IMAGE_TAG}" .
sudo podman push "${OCI_IMAGE_REPO}:${OCI_IMAGE_TAG}"

sudo podman tag \
  "${OCI_IMAGE_REPO}:${OCI_IMAGE_TAG}" \
  "localhost/device-os:${OCI_IMAGE_TAG}"
```

## Step 5 — Generate the VMDK artifact

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

## Step 6 — Build the late-binding cloud-init seed

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

If your generated file shows a different host that is not covered by the Edge Manager API certificate, replace those values before you provision the VM.

Use [`../bootc/vmdk-latebinding/user-data.yaml`](../bootc/vmdk-latebinding/user-data.yaml) as the starting point for the provisioning-time cloud-init payload. Create a new `user-data` file with those contents. It writes the enrollment configuration into the VM at first boot.

Replace:

- `CHANGEME_PASTE_CONFIG_YAML_HERE` with the full contents of `config.yaml`

Create the matching `meta-data` file:

```bash
cat > meta-data <<'EOF'
instance-id: rhem-vsphere-latebinding-01
local-hostname: rhem-vsphere-latebinding-01
EOF
```

Build a NoCloud seed ISO:

```bash
genisoimage -output seed.iso -volid cidata -joliet -rock user-data meta-data
```

If `genisoimage` is not installed on the build host, install it first:

```bash
sudo dnf install -y genisoimage
```

## Step 7 — Create the VM in vSphere

In the vSphere Client:

1. Upload the VMDK output directory to a datastore folder.
2. Upload `seed.iso` to the same datastore or another datastore the VM can access.
3. Create a new virtual machine.
4. Set:
   - Guest OS family: `Linux`
   - Guest OS version: `Red Hat Enterprise Linux 9 (64-bit)`
5. Allocate at least:
   - `2` vCPUs
   - `4 GiB` RAM
6. Remove the default hard disk.
7. Add an existing hard disk and select the uploaded `disk.vmdk`.
8. Add a CD/DVD drive and attach `seed.iso`.
9. Connect the CD/DVD drive at power on.
10. Use a network that can reach:
    - the Edge Manager API hostname
    - `quay.io`
11. Power on the VM.

Because this is the late-binding flow, the VM needs both the VMDK disk and the NoCloud seed ISO at first boot.

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
