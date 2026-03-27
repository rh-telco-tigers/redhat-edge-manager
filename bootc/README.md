# bootc

This folder contains the shared bootc build source used by both the manual labs and the automation.

Use one of these variants:

- `earlybinding/` builds an image that already contains `/etc/flightctl/config.yaml`
- `latebinding/` builds an image without that enrollment file or the Satellite registry CA, so you provide both later through cloud-init when you provision each device
  - that folder also includes a plain `user-data.yaml` example for the provisioning-time payload
- `vmdk-earlybinding/` builds the VMware-targeted early-binding image with `open-vm-tools`
- `vmdk-latebinding/` builds the VMware-targeted late-binding image with `cloud-init` and `open-vm-tools`

Manual labs:

- [`../labs/03a-bootc-earlybinding.md`](../labs/03a-bootc-earlybinding.md)
- [`../labs/03b-bootc-latebinding.md`](../labs/03b-bootc-latebinding.md)
- [`../labs/03c-bootc-vmdk-earlybinding.md`](../labs/03c-bootc-vmdk-earlybinding.md)
- [`../labs/03d-bootc-vmdk-latebinding.md`](../labs/03d-bootc-vmdk-latebinding.md)

Shared registry notes:

- [`../extras/publishing-images-to-satellite-registry.md`](../extras/publishing-images-to-satellite-registry.md)
- [`../extras/publishing-images-to-quay-registry.md`](../extras/publishing-images-to-quay-registry.md)

Automation:

- `make build-image-early`
- `make build-image-late`
- `make build-image-vmdk-early`
- `make build-image-vmdk-late`

The automation stores fetched artifacts under:

- `automation/artifacts/bootc/earlybinding/<rhem-host>/`
- `automation/artifacts/bootc/latebinding/<rhem-host>/`
- `automation/artifacts/bootc/vmdk-earlybinding/<rhem-host>/`
- `automation/artifacts/bootc/vmdk-latebinding/<rhem-host>/`
- `automation/artifacts/bootc/current/<rhem-host>/`

`current/` always points to the most recent qcow2-based build and is what `make add-device` uses by default. The VMDK build targets do not overwrite `current/`.
