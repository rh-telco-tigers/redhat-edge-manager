# Reference Notes

Most users should start at the repo root [README.md](../README.md).

Use `prereqs/` only when you want extra setup detail for the Proxmox-based automation path.

If you are following the labs manually on your own systems, you can usually skip this directory and stay in [`labs/`](../labs/).

If you want this repo to create the demo environment for you, start with [`automation/README.md`](../automation/README.md).

## Page

- [01-proxmox-terraform.md](01-proxmox-terraform.md) — how the Proxmox automation path works, which RHEL 9 guest image it expects, and what to configure before you run it
- [02-trusting-lab-certificates.md](02-trusting-lab-certificates.md) — how to export the Edge Manager certificate and trust it on your workstation so the browser and `flightctl` do not need insecure overrides
- [03-changing-edge-manager-base-domain.md](03-changing-edge-manager-base-domain.md) — how to set `global.baseDomain`, regenerate the built-in certificates, and understand why `flightctl certificate request` is not the server certificate rotation command
