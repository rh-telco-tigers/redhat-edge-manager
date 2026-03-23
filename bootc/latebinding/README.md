# latebinding

This variant builds the same device operating system image without embedding `/etc/flightctl/config.yaml` or the Satellite registry CA.

Use it when you want to decide the enrollment endpoint and certificate at provisioning time for each device and deliver them through cloud-init.

Files:

- `Containerfile`: bootc image definition without `config.yaml`
- `installer.toml`: `bootc-image-builder` installer config
- `rhem-demo-hosts.sh`: helper script that writes the management host entries into `/etc/hosts`
- `rhem-demo-hosts.service`: systemd unit that runs the helper script at boot
- `user-data.yaml`: example cloud-init payload for late binding

Build and push the image:

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

Build the bootable qcow2 artifact:

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

At provisioning time, request the enrollment config and place it into `user-data.yaml` together with the Satellite CA before first boot:

```bash
flightctl certificate request --signer enrollment --expiration 365d --output embedded > config.yaml

cp user-data.yaml user-data.rendered.yaml
```

Edit `user-data.rendered.yaml` and replace:

- `CHANGEME_PASTE_CONFIG_YAML_HERE` with the full contents of `config.yaml`
- `CHANGEME_PASTE_SATELLITE_CA_HERE` with the full contents of `satellite-ca.crt`
- `satellite.rhem-eap.lan` if your registry hostname is different

Attach that user-data to the VM or provisioning workflow together with the qcow2 or ISO you built.

This is the same structure used by `make build-image-late`. The automation requests the enrollment config, renders the matching cloud-init user data, fetches both artifacts into `automation/artifacts/bootc/latebinding/`, and then `make add-device` attaches that user-data when the current artifact is late binding.
