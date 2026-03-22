# bootc images with Satellite and a real build path

**Goal:** keep Satellite in the demo for managed RHEL content, then build a real early-bound bootc image and generate a bootable ISO for Lab 4.

**Prereqs:** Labs 1 and 2 are complete. `make up` has already created the RHEM, Keycloak, DNS, and Satellite VMs. If you want Satellite to sync Red Hat content, you also need your Red Hat Satellite manifest.

## Step 1 — Verify the Satellite server from the automated stack

Open the Satellite UI:

```text
https://satellite.rhem-eap.lan/
```

The full automation installs Satellite for you. The remaining Satellite work in this lab is content setup, not server installation.

## Step 2 — Import the Satellite manifest

In the Satellite UI:

1. Select the `RHEM Demo` organization.
2. Go to `Content` > `Subscriptions`.
3. Click `Manage Manifest`.
4. Upload the subscription manifest for this lab.

Without the manifest, Satellite cannot expose or sync the Red Hat repositories you need later.

## Step 3 — Sync the RHEL 9 content you want Satellite to manage

In the Satellite UI, enable and sync at least these repository sets for `x86_64`:

- `Red Hat Enterprise Linux 9 for x86_64 - BaseOS (RPMs)`
- `Red Hat Enterprise Linux 9 for x86_64 - AppStream (RPMs)`

Then publish them through a content view that you can later assign to hosts and activation keys.

For this lab, the important split is:

- Satellite manages mirrored RPM content and lifecycle
- your bootc image still lives in Podman storage or an OCI registry
- Satellite does not replace the OCI registry for the final bootc image

## Step 4 — Request an enrollment config for early binding

Build the image on the RHEM host or use the automation path later in this lab. The early-binding config is created with the real `flightctl` flow:

```bash
export RHEM_API_URL="https://rhem-prereq-rhel-01.rhem-eap.lan:3443"
flightctl login "$RHEM_API_URL" \
  --username edgemanager-admin \
  --password 'CHANGEME-edgemanager-password' \
  --insecure-skip-tls-verify

flightctl certificate request \
  --signer enrollment \
  --expiration 365d \
  --output embedded > config.yaml
```

That `config.yaml` is what gets embedded into the image for the first enrollment.

## Step 5 — Create the actual Containerfile

Use a real `bootc` Containerfile instead of a placeholder. This is the same pattern the repo automation uses:

```Dockerfile
FROM registry.redhat.io/rhel9/rhel-bootc:9.7

RUN dnf -y install 'dnf-command(config-manager)' && \
    dnf config-manager --set-enabled edge-manager-1.0-for-rhel-9-x86_64-rpms && \
    dnf -y install flightctl-agent && \
    dnf -y clean all && \
    systemctl enable flightctl-agent.service && \
    systemctl mask bootc-fetch-apply-updates.timer

ADD config.yaml /etc/flightctl/
```

What this does:

- starts from the supported RHEL 9 `bootc` base image
- layers in `flightctl-agent`
- disables the default `bootc` auto-update timer because Edge Manager owns updates
- embeds the early-binding `config.yaml` so the device can enroll on first boot

## Step 6 — Build the bootc image

From the build directory:

```bash
export OCI_IMAGE_REPO="localhost/rhem-demo/device-os"
export OCI_IMAGE_TAG="v1"
sudo podman build -t "${OCI_IMAGE_REPO}:${OCI_IMAGE_TAG}" .
```

For the demo, a local Podman image reference is enough to build the ISO. If you want later over-the-air updates from a registry, switch `OCI_IMAGE_REPO` to a real writable registry path.

## Step 7 — Optionally sign and publish the bootc image

If you have a real OCI registry for the demo, use the Red Hat flow:

```bash
skopeo generate-sigstore-key --output-prefix signingkey

export OCI_REGISTRY="registry.example.com"
sudo tee "/etc/containers/registries.d/${OCI_REGISTRY}.yaml" > /dev/null <<EOF
docker:
  ${OCI_REGISTRY}:
    use-sigstore-attachments: true
EOF

sudo podman login "${OCI_REGISTRY}"
sudo podman push \
  --sign-by-sigstore-private-key ./signingkey.private \
  "${OCI_IMAGE_REPO}:${OCI_IMAGE_TAG}"
```

If you skip this step, you can still boot the ISO in Lab 4. You just will not have a remote registry-backed update source yet.

## Step 8 — Build the bootable ISO

Use `bootc-image-builder` to turn the bootc image into an installer ISO:

```bash
mkdir -p output

sudo podman run --rm -it --privileged --pull=newer \
  --security-opt label=type:unconfined_t \
  -v "${PWD}/output":/output \
  -v /var/lib/containers/storage:/var/lib/containers/storage \
  registry.redhat.io/rhel9/bootc-image-builder:latest \
  --type iso \
  "${OCI_IMAGE_REPO}:${OCI_IMAGE_TAG}"
```

When it finishes, the ISO is here:

```text
output/bootiso/install.iso
```

## Step 9 — Optional: publish the ISO as an OCI artifact

If you want the ISO in the same registry path:

```bash
sudo chown -R "$(whoami)":"$(whoami)" output
export OCI_DISK_IMAGE_REPO="${OCI_IMAGE_REPO}/diskimage-iso"

sudo podman manifest create "${OCI_DISK_IMAGE_REPO}:${OCI_IMAGE_TAG}"
sudo podman manifest add \
  --artifact --artifact-type application/vnd.diskimage.iso \
  --arch=amd64 --os=linux \
  "${OCI_DISK_IMAGE_REPO}:${OCI_IMAGE_TAG}" \
  "${PWD}/output/bootiso/install.iso"
sudo podman manifest push --all \
  --sign-by-sigstore-private-key ./signingkey.private \
  "${OCI_DISK_IMAGE_REPO}:${OCI_IMAGE_TAG}" \
  "docker://${OCI_DISK_IMAGE_REPO}:${OCI_IMAGE_TAG}"
```

## Step 10 — Use the automation path instead of the manual commands

The repo now automates the real build on the RHEM host:

```bash
make bootc-build
```

By default this does all of the following:

- logs in to Edge Manager on the RHEM host
- requests the early-binding enrollment config
- renders the real Containerfile above
- builds `localhost/rhem-demo/device-os:v1`
- generates the ISO with `bootc-image-builder`
- fetches the ISO back to your laptop at:

```text
automation/artifacts/bootc/rhem-prereq-rhel-01/install.iso
```

If you want the automation to publish signed artifacts to a real OCI registry, set these in `automation/ansible/group_vars/all.yml` before rerunning `make bootc-build`:

- `bootc_image_repo`
- `bootc_publish_enabled: true`
- `bootc_registry`
- `bootc_registry_username`
- `bootc_registry_password`
