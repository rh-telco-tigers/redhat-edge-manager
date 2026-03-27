# vmdk-earlybinding

This variant builds a VMware-targeted bootc image with the Edge Manager enrollment configuration already embedded.

Use it when you want to:

- generate a `vmdk` disk image for VMware vSphere
- include `/etc/flightctl/config.yaml` in the image
- boot the VM without attaching a cloud-init seed ISO

Files:

- `Containerfile`: VMware-oriented bootc image definition with `open-vm-tools`
- `rhem-demo-hosts.sh`: helper script that writes the management host entries into `/etc/hosts`
- `rhem-demo-hosts.service`: systemd unit that runs the helper script at boot

Before you build:

1. Generate `config.yaml` from Edge Manager.
2. Place the SSH public key you want in the image as `demo-authorized-key.pub`.

Then build and push the image:

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

This is the same source used by `make build-image-vmdk-early`.
