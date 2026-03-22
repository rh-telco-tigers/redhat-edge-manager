# Deploy an application through Edge Manager

**Goal:** build one application image, package it for Edge Manager, publish both images to Satellite, and deploy the application to the enrolled device through the fleet.

**Prereqs:** Labs 1 to 5 are complete. At least one device is enrolled, online, and selected by `Fleet/demo`.

## Step 1 — Create the CLI context and confirm the target device

```bash
export EDGE_MANAGER_HOST="edge-manager.example.com"
export EDGE_MANAGER_API_URL="https://${EDGE_MANAGER_HOST}:3443"

flightctl login "${EDGE_MANAGER_API_URL}" \
  --username edgemanager-admin \
  --password 'CHANGEME-edgemanager-password' \
  --insecure-skip-tls-verify

flightctl get fleets
flightctl get devices -o wide
```

If you have old disconnected device entries from earlier test runs, delete them before continuing:

```bash
flightctl delete device/CHANGEME_OLD_DEVICE_ID
```

## Step 2 — Define the Satellite image paths

```bash
export SATELLITE_HOST="satellite.example.com"
export SATELLITE_ORG_ID="CHANGEME_ORG_ID"
export SATELLITE_PRODUCT_ID="CHANGEME_PRODUCT_ID"
export APP_TAG="v1"

export DEMO_RUNTIME_IMAGE_REPO="${SATELLITE_HOST}/id/${SATELLITE_ORG_ID}/${SATELLITE_PRODUCT_ID}/hello-web-runtime"
export DEMO_PACKAGE_IMAGE_REPO="${SATELLITE_HOST}/id/${SATELLITE_ORG_ID}/${SATELLITE_PRODUCT_ID}/hello-web-package"
export FLEET_IMAGE_REF="${SATELLITE_HOST}/id/${SATELLITE_ORG_ID}/${SATELLITE_PRODUCT_ID}/device-os:v1"
```

If you need to confirm the organization or product IDs:

```bash
ssh <admin_user>@${SATELLITE_HOST}
sudo hammer --output csv organization list
sudo hammer --output csv product list --organization-id CHANGEME_ORG_ID
```

## Step 3 — Build the runtime image

Use any RHEL build host that has Podman and network access to Satellite. The example below uses the Edge Manager host:

```bash
ssh <admin_user>@${EDGE_MANAGER_HOST}
mkdir -p ~/hello-web/runtime ~/hello-web/package
cd ~/hello-web

curl -k "https://${SATELLITE_HOST}/pub/katello-server-ca.crt" \
  -o satellite-ca.crt

sudo mkdir -p /etc/containers/certs.d/${SATELLITE_HOST}
sudo cp satellite-ca.crt /etc/containers/certs.d/${SATELLITE_HOST}/ca.crt
sudo cp satellite-ca.crt /etc/pki/ca-trust/source/anchors/${SATELLITE_HOST}.crt
sudo update-ca-trust

sudo podman login "${SATELLITE_HOST}" \
  --username admin \
  --password 'CHANGEME-satellite-admin-password'
```

Create the application content:

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

Create the runtime `Containerfile`:

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

Create the quadlet definition:

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

Create the package `Containerfile`:

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

## Step 5 — Update the fleet to deploy the application

Create `fleet-with-app.yaml`:

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

## Step 6 — Verify the application in Edge Manager

```bash
flightctl get fleets/demo -o yaml
flightctl get devices -o yaml
```

In the device status, look for `hello-web` under `status.applications` with a `Running` state.

In the Edge Manager web console, open the device and check the Applications view.

## Step 7 — Spot-check the running container on the device

If you can SSH to the device, confirm that the container is running and serving content:

```bash
ssh <device_user>@CHANGEME_DEVICE_HOST

sudo podman ps
curl -s http://127.0.0.1:8080/
```

The HTTP response should return the demo page that you created in Step 3.
