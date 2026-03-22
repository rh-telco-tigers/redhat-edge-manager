# Deploy an application through Edge Manager

**Goal:** build one simple containerized application, publish it into the customer-like Satellite registry, and let Edge Manager deploy it to the enrolled device through the existing fleet.

**Important:** Edge Manager is still the control plane in this lab:

- Satellite only hosts the OCI images.
- Edge Manager decides which device should run the application.
- The application is attached to the fleet, not installed by SSHing to the device.

**Prereqs:** Labs 1 to 5 are complete. At least one device is enrolled, online, and selected by `Fleet/demo`.

This lab uses a quadlet wrapper image for a single container. The runtime image and the wrapper image both live in Satellite, but Edge Manager remains the control plane that decides which device runs the app.

## Step 1 — Confirm the device is already in the demo fleet

```bash
export RHEM_API_URL="https://rhem.rhem-eap.lan:3443"

flightctl login "$RHEM_API_URL" \
  --username edgemanager-admin \
  --password 'CHANGEME-edgemanager-password' \
  --insecure-skip-tls-verify

flightctl get fleets
flightctl get devices -o wide
```

The device should already have the `fleet=demo` label from Lab 4 and should already be owned by `Fleet/demo` from Lab 5.

If you rebuilt the demo device more than once, clean up any old disconnected device entry before continuing:

```bash
flightctl get devices -o wide
flightctl delete device/CHANGEME_OLD_DEVICE_ID
```

## Step 2 — Define the Satellite image paths for the application

For this demo, keep the application images in the same Satellite product family used earlier.

```bash
export SATELLITE_REGISTRY="satellite.rhem-eap.lan"
export SATELLITE_ORG_ID="1"
export SATELLITE_PRODUCT_ID="1"
export APP_TAG="v3"

export DEMO_RUNTIME_IMAGE_REPO="${SATELLITE_REGISTRY}/id/${SATELLITE_ORG_ID}/${SATELLITE_PRODUCT_ID}/hello-web-runtime"
export DEMO_PACKAGE_IMAGE_REPO="${SATELLITE_REGISTRY}/id/${SATELLITE_ORG_ID}/${SATELLITE_PRODUCT_ID}/hello-web-package"
```

If your Satellite uses different IDs, use the real values from:

```bash
ssh cloud-user@192.168.4.38
sudo hammer --output csv organization list
sudo hammer --output csv product list --organization-id 1
```

## Step 3 — Build the runtime image that the device will actually run

Work on the RHEM host so you can reuse the same registry access and CA trust path as the earlier labs:

```bash
ssh cloud-user@192.168.4.35
mkdir -p ~/hello-web/runtime ~/hello-web/package
cd ~/hello-web

curl -k https://satellite.rhem-eap.lan/pub/katello-server-ca.crt \
  -o satellite-ca.crt

sudo mkdir -p /etc/containers/certs.d/satellite.rhem-eap.lan
sudo cp satellite-ca.crt /etc/containers/certs.d/satellite.rhem-eap.lan/ca.crt
sudo cp satellite-ca.crt /etc/pki/ca-trust/source/anchors/satellite-rhem-eap-lan.crt
sudo update-ca-trust

sudo podman login satellite.rhem-eap.lan \
  --username admin \
  --password 'CHANGEME-satellite-admin-password'
```

Create the web content:

```bash
cat > runtime/index.html <<'EOF'
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <title>Red Hat Edge Manager Demo App</title>
</head>
<body>
  <h1>Red Hat Edge Manager Demo App</h1>
  <p>Managed by Red Hat Edge Manager</p>
</body>
</html>
EOF
```

Create the runtime Containerfile:

```bash
cat > runtime/Containerfile <<'EOF'
FROM registry.access.redhat.com/ubi9/httpd-24:latest

COPY index.html /var/www/html/index.html
EOF
```

Build and push the runtime image:

```bash
sudo podman build \
  -t "${DEMO_RUNTIME_IMAGE_REPO}:${APP_TAG}" \
  -f runtime/Containerfile \
  runtime

sudo podman push "${DEMO_RUNTIME_IMAGE_REPO}:${APP_TAG}"
```

## Step 4 — Build the Edge Manager application package image

Edge Manager does not point directly at the runtime image in this lab. It points at a small OCI package image that contains a quadlet definition telling the device how to run that container.

Create the quadlet file:

```bash
cat > package/application.container <<EOF
[Unit]
Description=Red Hat Edge Manager Demo App

[Container]
Image=${DEMO_RUNTIME_IMAGE_REPO}:${APP_TAG}
PublishPort=8080:8080

[Service]
Restart=always

[Install]
WantedBy=multi-user.target
EOF
```

Create the package Containerfile:

```bash
cat > package/Containerfile <<'EOF'
FROM scratch

COPY application.container /application.container

LABEL appType=quadlet
EOF
```

Build and push the package image:

```bash
sudo podman build \
  -t "${DEMO_PACKAGE_IMAGE_REPO}:${APP_TAG}" \
  -f package/Containerfile \
  package

sudo podman push "${DEMO_PACKAGE_IMAGE_REPO}:${APP_TAG}"
```

## Step 5 — Update the fleet so Edge Manager deploys the application

Reuse the same OS image reference from Lab 5:

```bash
export FLEET_IMAGE_REF="${SATELLITE_REGISTRY}/id/${SATELLITE_ORG_ID}/${SATELLITE_PRODUCT_ID}/device-os:v1"
```

Create `fleet-with-app.yaml` on the RHEM host:

```bash
cat > fleet-with-app.yaml <<EOF
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
        image: "${FLEET_IMAGE_REF}"
      applications:
        - name: "hello-web"
          appType: "quadlet"
          image: "${DEMO_PACKAGE_IMAGE_REPO}:${APP_TAG}"
EOF
```

Apply it:

```bash
flightctl apply -f fleet-with-app.yaml
```

This is the key point of the lab: the application is now managed by Edge Manager through the fleet definition, just like the OS image is.

## Step 6 — Verify the application from Edge Manager

Check the fleet and device status:

```bash
flightctl get fleets/demo -o yaml
flightctl get devices -o yaml
```

In the device status, look for an entry under `status.applications` named `hello-web` with a healthy or running state.

In the browser UI:

- open `https://rhem-prereq-rhel-01.rhem-eap.lan/`
- open the enrolled device
- open the Applications section

You should see the `hello-web` workload managed by Edge Manager.

## Step 7 — Spot-check the running container on the device

SSH to the device and confirm the container is running:

```bash
ssh cloud-user@CHANGEME_DEVICE_IP

sudo podman ps
curl -s http://127.0.0.1:8080/
```

If you kept the default quadlet definition, the local HTTP check should return the demo HTML page.

## Step 8 — Use the repo automation for the same flow

Build the runtime image and the Edge Manager package image:

```bash
make app-build
```

Update the demo fleet and wait for the application to report `Running` on the fleet-managed device:

```bash
make app-deploy
```

Run the full Lab 6 automation in one step after Labs 3 to 5 are already complete:

```bash
make app-demo
```

The repo automation uses the same model described above:

- build the runtime image
- build the quadlet package image
- push both to Satellite
- update `Fleet/demo`
- wait for the application to start on the enrolled device
