# Performance optimization

**Goal:** capture a baseline for the enrolled device, apply one controlled application tuning change, and compare the results before and after the rollout.

**Prereqs:** Labs 1 to 6 are complete. The demo application is already deployed through `Fleet/demo`.

## Step 1 — Create the working context

```bash
export EDGE_MANAGER_HOST="rhem.rhem-eap.lan"
export EDGE_MANAGER_API_URL="https://${EDGE_MANAGER_HOST}:3443"
export SATELLITE_HOST="satellite.rhem-eap.lan"
export SATELLITE_ORG_ID="CHANGEME_ORG_ID"
export SATELLITE_PRODUCT_ID="CHANGEME_PRODUCT_ID"
export DEVICE_NAME="CHANGEME_DEVICE_NAME"
export DEVICE_HOST="CHANGEME_DEVICE_HOST"
export APP_TAG_BASELINE="v3"
export APP_TAG_TUNED="v4"

export DEMO_RUNTIME_IMAGE_REPO="${SATELLITE_HOST}/id/${SATELLITE_ORG_ID}/${SATELLITE_PRODUCT_ID}/hello-web-runtime"
export DEMO_PACKAGE_IMAGE_REPO="${SATELLITE_HOST}/id/${SATELLITE_ORG_ID}/${SATELLITE_PRODUCT_ID}/hello-web-package"
export FLEET_OS_IMAGE_REF="${SATELLITE_HOST}/id/${SATELLITE_ORG_ID}/${SATELLITE_PRODUCT_ID}/device-os:v1"

flightctl login "${EDGE_MANAGER_API_URL}" \
  --username edgemanager-admin \
  --password 'CHANGEME-edgemanager-password' \
  --insecure-skip-tls-verify
```

## Step 2 — Capture the baseline

Save the current fleet and device state:

```bash
mkdir -p performance-baseline

flightctl get fleets/demo -o yaml > performance-baseline/fleet-demo-before.yaml
flightctl get device "${DEVICE_NAME}" -o yaml > performance-baseline/device-before.yaml
```

If you can SSH to the device, capture host and container state:

```bash
ssh <device_user>@${DEVICE_HOST}

uptime
free -h
df -h
sudo podman stats --no-stream
sudo ss -lntp
```

If the application is reachable over the network, capture a simple response-time sample from a nearby host:

```bash
curl -s -o /dev/null \
  -w 'connect=%{time_connect} starttransfer=%{time_starttransfer} total=%{time_total}\n' \
  "http://${DEVICE_HOST}:8080/"
```

## Step 3 — Build a tuned application package image

Use the same runtime image from Lab 6 and publish a new package image with explicit container limits.

On your build host:

```bash
mkdir -p ~/hello-web-tuned/package
cd ~/hello-web-tuned

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

Create a tuned quadlet definition:

```bash
cat > package/application.container <<EOF
[Unit]
Description=Red Hat Edge Manager Demo App Tuned

[Container]
Image=${DEMO_RUNTIME_IMAGE_REPO}:${APP_TAG_BASELINE}
PublishPort=8080:8080
PodmanArgs=--memory=256m --cpus=1.0 --pids-limit=256 --read-only

[Service]
Restart=always
RestartSec=5

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

Build and push the tuned package image:

```bash
sudo podman build \
  -t "${DEMO_PACKAGE_IMAGE_REPO}:${APP_TAG_TUNED}" \
  -f package/Containerfile \
  package

sudo podman push "${DEMO_PACKAGE_IMAGE_REPO}:${APP_TAG_TUNED}"
```

## Step 4 — Update the fleet to use the tuned package

Create a new fleet manifest:

```bash
cat > fleet-with-tuned-app.yaml <<EOF
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
        image: "${FLEET_OS_IMAGE_REF}"
      applications:
        - name: "hello-web"
          appType: "quadlet"
          image: "${DEMO_PACKAGE_IMAGE_REPO}:${APP_TAG_TUNED}"
EOF
```

Apply it:

```bash
flightctl apply -f fleet-with-tuned-app.yaml
```

Wait until the device returns to `UpToDate` and the application reports `Running`.

## Step 5 — Capture the tuned result

Save the updated fleet and device state:

```bash
flightctl get fleets/demo -o yaml > performance-baseline/fleet-demo-after.yaml
flightctl get device "${DEVICE_NAME}" -o yaml > performance-baseline/device-after.yaml
```

Repeat the same device checks:

```bash
ssh <device_user>@${DEVICE_HOST}

uptime
free -h
df -h
sudo podman stats --no-stream
sudo podman inspect hello-web
```

Repeat the same response-time sample:

```bash
curl -s -o /dev/null \
  -w 'connect=%{time_connect} starttransfer=%{time_starttransfer} total=%{time_total}\n' \
  "http://${DEVICE_HOST}:8080/"
```

Compare:

- container memory and CPU usage
- host free memory
- application response time
- Edge Manager rollout health

## Step 6 — Roll back if needed

If the tuned package performs worse, point the fleet back to the previous package tag:

```bash
sed "s/${APP_TAG_TUNED}/${APP_TAG_BASELINE}/" fleet-with-tuned-app.yaml > fleet-with-baseline-app.yaml
flightctl apply -f fleet-with-baseline-app.yaml
```
