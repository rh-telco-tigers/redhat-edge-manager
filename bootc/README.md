# bootc

This folder is the source of truth for the demo device OS build.

Automation uses these same files when you run `make bootc-build`.

Files:

- `Containerfile`: the bootc image definition
- `installer.toml`: the `bootc-image-builder` installer Kickstart config
- `rhem-demo-hosts.sh`: helper script that writes the management host entries into `/etc/hosts`
- `rhem-demo-hosts.service`: systemd unit that runs the helper script at boot

`config.yaml` is generated from Edge Manager and is not stored in git. Generate it with:

```bash
flightctl certificate request --signer enrollment --expiration 365d --output embedded > config.yaml
```

If you follow the manual lab, place that generated `config.yaml` next to these files in your local bootc build context.

Manual flow:

1. Generate `config.yaml` from Edge Manager and place it next to these files.
2. Download the Satellite CA certificate as `satellite-ca.crt`.
3. Place the SSH public key you want in the image as `demo-authorized-key.pub`.
4. Use these files directly. If your environment does not use `rhem.rhem-eap.lan` or `satellite.rhem-eap.lan`, edit the obvious hostnames in `Containerfile` and `rhem-demo-hosts.sh`.
5. Build and push the image to Satellite:

```bash
sudo podman build -t "${SATELLITE_IMAGE_REPO}:${OCI_IMAGE_TAG}" .
sudo podman push "${SATELLITE_IMAGE_REPO}:${OCI_IMAGE_TAG}"
```

6. Tag the same image locally for `bootc-image-builder`:

```bash
sudo podman tag \
  "${SATELLITE_IMAGE_REPO}:${OCI_IMAGE_TAG}" \
  "localhost/device-os:${OCI_IMAGE_TAG}"
```

7. Build the qcow2 artifact:

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

Automation path:

- `make bootc-build` copies these same files, adjusts the few environment-specific values automatically, and fetches the built qcow2 into `automation/artifacts/bootc/<rhem-host>/`.
