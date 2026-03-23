# earlybinding

This variant bakes the Edge Manager enrollment configuration into the bootc image.

Use it when you want the image itself to already contain:

- the enrollment endpoint
- the enrollment certificate and key material
- the `/etc/flightctl/config.yaml` file the device needs on first boot

Files:

- `Containerfile`: bootc image definition with `config.yaml` included
- `installer.toml`: `bootc-image-builder` installer config
- `rhem-demo-hosts.sh`: helper script that writes the management host entries into `/etc/hosts`
- `rhem-demo-hosts.service`: systemd unit that runs the helper script at boot

Before you build:

1. Generate `config.yaml` from Edge Manager:

```bash
flightctl certificate request --signer enrollment --expiration 365d --output embedded > config.yaml
```

2. Download the Satellite CA certificate as `satellite-ca.crt`.
3. Place the SSH public key you want in the image as `demo-authorized-key.pub`.

Then build and push the image:

```bash
sudo podman build -t "${SATELLITE_IMAGE_REPO}:${OCI_IMAGE_TAG}" .
sudo podman push "${SATELLITE_IMAGE_REPO}:${OCI_IMAGE_TAG}"
```

Tag the same image locally for `bootc-image-builder`:

```bash
sudo podman tag \
  "${SATELLITE_IMAGE_REPO}:${OCI_IMAGE_TAG}" \
  "localhost/device-os:${OCI_IMAGE_TAG}"
```

Build the bootable artifact:

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

This is the same source used by `make bootc-build`.
