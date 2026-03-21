# Prereq notes

Runnable automation now lives in [`automation/`](../automation/README.md). This `prereqs/` directory is kept for supporting notes, network assumptions, and alternate paths that are still useful while the automation grows.

Useful starting points:

- [docs/01-proxmox-terraform.md](docs/01-proxmox-terraform.md) — how the Proxmox guest-image workflow works now that it lives under `automation/terraform/`
- [docs/rhel-guest-image-proxmox.md](docs/rhel-guest-image-proxmox.md) — which RHEL qcow2 image Terraform expects
- [docs/02-aap-single-node.md](docs/02-aap-single-node.md) — background on the single-node AAP option
- [docs/03-edge-manager-rhacm.md](docs/03-edge-manager-rhacm.md) — alternate RHACM path
