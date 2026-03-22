# Build the bootc image and publish it through Satellite

**Goal:** build the Edge Manager device OS image, store it in Satellite's registry, and generate the unattended installer ISO that you will use to onboard a fresh device in the next lab.

**Important:** this lab is still about Edge Manager. Satellite is only the customer-like supporting environment here:

- Satellite hosts the bootc image and RHEL content
- Edge Manager still owns enrollment, fleets, and device lifecycle

**Prereqs:** Labs 1 and 2 are complete. `make up` already created the RHEM, Keycloak, DNS, and Satellite VMs.

## Step 1 — Verify the supporting services

Open:

```text
https://satellite.rhem-eap.lan/
https://rhem-prereq-rhel-01.rhem-eap.lan/
```

The remaining work in this lab is image and registry preparation, not service installation.

## Step 2 — Optional: import the Satellite manifest and sync RHEL content

If you want Satellite to look more like a customer environment, import your manifest and enable at least:

- `Red Hat Enterprise Linux 9 for x86_64 - BaseOS (RPMs)`
- `Red Hat Enterprise Linux 9 for x86_64 - AppStream (RPMs)`

This is useful for later content-management demos, but it is not what makes the Edge Manager bootc flow work.

## Step 3 — Prepare the Satellite registry path for the bootc image

SSH to the Satellite host:

```bash
ssh cloud-user@192.168.4.38
```

Find the organization ID:

```bash
sudo hammer --output csv organization list
```

Create the custom product once if it does not already exist:

```bash
sudo hammer product create \
  --organization-id 1 \
  --name bootc \
  --label bootc
```

List products so you can capture the product ID for `bootc`:

```bash
sudo hammer --output csv product list --organization-id 1
```

Allow anonymous pull from the `Library` lifecycle environment so the device does not need a registry pull secret for this demo:

```bash
sudo hammer lifecycle-environment update \
  --organization-id 1 \
  --name Library \
  --registry-unauthenticated-pull true
```

Set the image repository path for the next steps. Use the real product ID from the previous command:

```bash
export SATELLITE_IMAGE_REPO="satellite.rhem-eap.lan/id/1/CHANGEME_PRODUCT_ID/device-os"
export OCI_IMAGE_TAG="v1"
```

## Step 4 — Request the early-binding enrollment config from Edge Manager

On the RHEM host:

```bash
ssh cloud-user@192.168.4.35
```

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

That `config.yaml` is what makes the installed system enroll automatically in Lab 4.

## Step 5 — Build the actual bootc image

Fetch the Satellite CA certificate:

```bash
curl -k https://satellite.rhem-eap.lan/pub/katello-server-ca.crt \
  -o satellite-ca.crt
```

Create the real Containerfile:

```Dockerfile
FROM registry.redhat.io/rhel9/rhel-bootc:9.7

RUN dnf -y install 'dnf-command(config-manager)' && \
    dnf config-manager --set-enabled edge-manager-1.0-for-rhel-9-x86_64-rpms && \
    dnf -y install flightctl-agent && \
    dnf -y clean all && \
    systemctl enable flightctl-agent.service && \
    systemctl mask bootc-fetch-apply-updates.timer

RUN mkdir -p /etc/containers/certs.d/satellite.rhem-eap.lan
ADD satellite-ca.crt /etc/pki/ca-trust/source/anchors/satellite-ca.crt
ADD satellite-ca.crt /etc/containers/certs.d/satellite.rhem-eap.lan/ca.crt
RUN update-ca-trust

ADD config.yaml /etc/flightctl/
```

If your DHCP server does not hand out DNS for `rhem-eap.lan`, add the same management host mappings that the repo automation adds before you build the image. The automated path already handles that for you.

Build and push the image to Satellite:

```bash
sudo podman login satellite.rhem-eap.lan \
  --username admin \
  --password 'CHANGEME-satellite-admin-password'

sudo podman build -t "${SATELLITE_IMAGE_REPO}:${OCI_IMAGE_TAG}" .

sudo podman push "${SATELLITE_IMAGE_REPO}:${OCI_IMAGE_TAG}"

sudo podman tag \
  "${SATELLITE_IMAGE_REPO}:${OCI_IMAGE_TAG}" \
  "localhost/rhem-demo/device-os:${OCI_IMAGE_TAG}"
```

## Step 6 — Generate the unattended installer ISO

If your environment already provides working DNS for the demo domain, you can build the ISO without any extra installer customization:

```bash
mkdir -p output

sudo podman run --rm -it --privileged --pull=newer \
  --security-opt label=type:unconfined_t \
  -v "${PWD}/output":/output \
  -v /var/lib/containers/storage:/var/lib/containers/storage \
  registry.redhat.io/rhel9/bootc-image-builder:latest \
  --type iso \
  --local \
  "localhost/rhem-demo/device-os:${OCI_IMAGE_TAG}"
```

If you need to override installer-time DNS or force `reboot --eject`, use an optional `config.toml`:

```bash
cat > config.toml <<'EOF'
[customizations.installer.kickstart]
contents = """
network --bootproto=dhcp --device=link --activate --onboot=on --nameserver=192.168.4.30
reboot --eject
"""
EOF

mkdir -p output

sudo podman run --rm -it --privileged --pull=newer \
  --security-opt label=type:unconfined_t \
  -v "${PWD}/config.toml":/config.toml \
  -v "${PWD}/output":/output \
  -v /var/lib/containers/storage:/var/lib/containers/storage \
  registry.redhat.io/rhel9/bootc-image-builder:latest \
  --type iso \
  --local \
  --config /config.toml \
  "localhost/rhem-demo/device-os:${OCI_IMAGE_TAG}"
```

Main artifact:

```text
output/bootiso/install.iso
```

That ISO is the artifact you use for both:

- the manual Lab 4 device boot path
- the repo-managed Proxmox device VM path in `make device-vm-up`

The optional `config.toml` matters only when the installer must resolve your management environment differently than the default network provides. Point the installer DNS at your demo DNS VM, not at a public resolver. Keep this Kickstart fragment minimal; `bootc-image-builder` already carries the install logic, and here you are only overriding the network/DNS behavior and post-install eject.

The local `localhost/rhem-demo/device-os:${OCI_IMAGE_TAG}` tag is intentional. Current RHEL `bootc-image-builder` has a documented limitation with private registries, so the practical workaround is to keep Satellite as the hosted registry of record, then stage the same image into local container storage and build the ISO with `--local`.

If you want a secondary virtualization artifact for side experiments, the repo automation also fetches a `qcow2`, but it is not the main onboarding path in this lab flow.

## Step 7 — Use the repo automation for the same flow

The repo now automates the practical version of this lab:

```bash
make bootc-build
```

By default that automation:

- prepares the Satellite registry path for the image
- pushes the bootc image to Satellite
- stages the same image locally for `bootc-image-builder --local`
- embeds the Edge Manager enrollment config
- embeds the Satellite CA into the image
- generates the unattended installer ISO
- also fetches an optional `qcow2` for secondary experiments
- fetches the artifacts back to this repo

Local artifacts:

```text
automation/artifacts/bootc/rhem-prereq-rhel-01/install.iso
automation/artifacts/bootc/rhem-prereq-rhel-01/disk.qcow2
```
