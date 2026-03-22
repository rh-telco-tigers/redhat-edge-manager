# bootc images with a dedicated Satellite content source

**Goal:** stand up a dedicated Red Hat Satellite VM for managed RHEL content, then use that content path in your later bootc image work.

**Important:** Satellite must run on a freshly provisioned, dedicated RHEL 9 host. Do not install it on the existing Edge Manager VM or the Keycloak VM.

**Prereqs:** Labs 1 and 2 are complete; you already have an OCI registry for the final bootc image push; you have a Red Hat Satellite subscription and manifest available.

## Step 1 — Create a dedicated Satellite VM

Use the single-VM helper to create a fresh RHEL 9 VM for Satellite:

```bash
make create-rhel9 ROLE=satellite VM_ID=123 IPV4_CIDR=192.168.4.123/22
```

The `satellite` role uses lab-friendly defaults:

- 4 vCPU
- 20 GiB RAM
- 500 GiB disk
- hostname default: `rhem-satellite-01`
- DNS short name default: `satellite`

If you need different values, override them:

```bash
make create-rhel9 ROLE=satellite \
  VM_ID=123 \
  IPV4_CIDR=192.168.4.123/22 \
  VM_NAME=rhem-satellite-01 \
  DNS_NAME=satellite
```

## Step 2 — Prepare the Satellite host

On the new Satellite VM, verify the basic install prerequisites:

```bash
hostnamectl
hostname -f
ping -c1 "$(hostname -f)"
timedatectl
getenforce
df -h /
df -h /var
```

For this lab, make sure all of these are true before you continue:

- the host uses a full FQDN, not a short name
- forward DNS works for that FQDN
- reverse DNS works for the host IP
- SELinux is enabled
- the system clock is synchronized
- the host is dedicated to Satellite only

## Step 3 — Register the host and enable Satellite repositories

Follow the connected-network Satellite install path on the Satellite VM:

```bash
sudo subscription-manager register
sudo subscription-manager repos --disable="*"
sudo subscription-manager repos \
  --enable=rhel-9-for-x86_64-baseos-rpms \
  --enable=rhel-9-for-x86_64-appstream-rpms \
  --enable=satellite-6.17-for-rhel-9-x86_64-rpms \
  --enable=satellite-maintenance-6.17-for-rhel-9-x86_64-rpms
sudo dnf repolist enabled
```

Then install the Satellite packages:

```bash
sudo dnf upgrade -y
sudo dnf install -y satellite
```

## Step 4 — Run the Satellite installer

Use `tmux` or `screen` before you start, because the install can take a while:

```bash
sudo dnf install -y tmux
tmux new -s satellite-install
```

Run the initial Satellite install:

```bash
sudo satellite-installer --scenario satellite \
  --foreman-initial-organization "RHEM Demo" \
  --foreman-initial-location "Homelab" \
  --foreman-initial-admin-username admin \
  --foreman-initial-admin-password 'CHANGEME-satellite-admin-password'
```

If you lose your terminal session while it runs, check:

```bash
sudo tail -f /var/log/foreman-installer/satellite.log
```

## Step 5 — Open the required firewall services

On the Satellite VM:

```bash
sudo firewall-cmd \
  --add-port="8000/tcp" \
  --add-port="9090/tcp"
sudo firewall-cmd \
  --add-service=dns \
  --add-service=dhcp \
  --add-service=tftp \
  --add-service=http \
  --add-service=https \
  --add-service=puppetmaster
sudo firewall-cmd --runtime-to-permanent
sudo firewall-cmd --list-all
```

## Step 6 — Verify the Satellite UI

Open the Satellite web UI:

```text
https://satellite.rhem-eap.lan/
```

Log in with the initial admin account you created in the installer step.

## Step 7 — Import the Satellite manifest

In the Satellite UI:

1. Set the organization context you created during install.
2. Go to `Content` > `Subscriptions`.
3. Click `Manage Manifest`.
4. Upload the Red Hat Satellite manifest for this lab.

Without the manifest, you cannot sync the content that will back your later bootc image work.

## Step 8 — Sync the RHEL content you plan to use for bootc builds

At minimum, prepare the RHEL 9 content you expect to consume for your base image path.

Start with these ideas in Satellite:

- create a product or use the Red Hat product content you need
- sync the RHEL 9 BaseOS repositories
- sync the RHEL 9 AppStream repositories
- publish a content view for the bootc build path

Exact repository selection depends on how you plan to build and register the image build environment.

## Step 9 — Keep the image registry separate from Satellite

Satellite gives you managed RPM and subscription content. It does not replace the OCI registry where you push the final bootc images.

Keep a separate registry target for image pushes:

```bash
export REGISTRY="CHANGEME-registry.example.com"
export REGISTRY_NAMESPACE="CHANGEME-org"
export BASE_IMG="$REGISTRY/$REGISTRY_NAMESPACE/rhem-edge-base:CHANGEME_TAG"
export APP_IMG="$REGISTRY/$REGISTRY_NAMESPACE/rhem-edge-app:CHANGEME_TAG"
podman login "$REGISTRY"
```

## Step 10 — Continue with the actual bootc image build

Once Satellite is ready as a managed content source, continue with your bootc workflow from your build host.

Use Red Hat docs for the actual image build flow:

- build the base image
- build the app image
- push both images to your OCI registry
- convert the image to installation media if needed

```bash
podman --version
buildah --version 2>/dev/null || true

# Replace with your real Containerfile and build commands
# podman build -t "$BASE_IMG" -f Containerfile.base .
# podman push "$BASE_IMG"

# podman build -t "$APP_IMG" -f Containerfile.app .
# podman push "$APP_IMG"
```

If you convert the image to install media later:

```bash
# Example placeholder for bootc-image-builder output
ls -la ./out 2>/dev/null || echo "Set out/ path after conversion"
```
