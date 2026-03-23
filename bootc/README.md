# bootc

This folder contains the shared bootc build source used by both the manual labs and the automation.

Use one of these two variants:

- `earlybinding/` builds an image that already contains `/etc/flightctl/config.yaml`
- `latebinding/` builds an image without that enrollment file or the Satellite registry CA, so you provide both later through cloud-init when you provision each device
  - that folder also includes a plain `user-data.yaml` example for the provisioning-time payload

Manual labs:

- [`../labs/03a-bootc-earlybinding.md`](../labs/03a-bootc-earlybinding.md)
- [`../labs/03b-bootc-latebinding.md`](../labs/03b-bootc-latebinding.md)

Automation:

- `make build-image-early`
- `make build-image-late`

The automation stores fetched artifacts under:

- `automation/artifacts/bootc/earlybinding/<rhem-host>/`
- `automation/artifacts/bootc/latebinding/<rhem-host>/`
- `automation/artifacts/bootc/current/<rhem-host>/`

`current/` always points to the most recent build and is what `make add-device` uses by default.
