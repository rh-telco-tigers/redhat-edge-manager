# vmdk-latebinding

This variant builds a VMware-targeted bootc image without embedding the Edge Manager enrollment configuration.

Use it when you want to:

- generate a clean `vmdk` disk image for VMware vSphere
- decide the enrollment endpoint and certificate at provisioning time
- attach a NoCloud seed ISO with `user-data` and `meta-data` when you create each VM

Files:

- `Containerfile`: VMware-oriented bootc image definition with `cloud-init` and `open-vm-tools`
- `rhem-demo-hosts.sh`: helper script that writes the management host entries into `/etc/hosts`
- `rhem-demo-hosts.service`: systemd unit that runs the helper script at boot
- `user-data.yaml`: example cloud-init payload for late binding

Build and push the image:

```bash
sudo podman build -t "${OCI_IMAGE_REPO}:${OCI_IMAGE_TAG}" .
sudo podman push "${OCI_IMAGE_REPO}:${OCI_IMAGE_TAG}"

sudo podman tag \
  "${OCI_IMAGE_REPO}:${OCI_IMAGE_TAG}" \
  "localhost/device-os:${OCI_IMAGE_TAG}"
```

Build the VMDK artifact:

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

At provisioning time, render `user-data.yaml` with the Edge Manager enrollment config, create a NoCloud seed ISO, and attach it to the VM on first boot.

This is the same source used by `make build-image-vmdk-late`.
