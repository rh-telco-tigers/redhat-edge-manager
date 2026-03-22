# Prereqs and Reference Notes

Most users should start at the repo root [README.md](../README.md).

Use this `prereqs/` section only when you need supporting information that sits outside the main lab flow, such as infrastructure setup notes or an alternate deployment path.

## When to use this directory

Open `prereqs/` if you need one of these:

- guidance for the Proxmox-based automation environment
- help preparing the RHEL guest image used by the Terraform workflow
- notes for the optional Ansible Automation Platform host
- the alternate Edge Manager deployment path through RHACM

If you are following the manual product labs, you can usually skip this directory and stay in [`labs/`](../labs/).

If you want the repo to create and configure the demo environment for you, start with [`automation/README.md`](../automation/README.md).

## Reference pages

- [docs/01-proxmox-terraform.md](docs/01-proxmox-terraform.md) — how the Proxmox automation path works and what to configure before you run it
- [docs/rhel-guest-image-proxmox.md](docs/rhel-guest-image-proxmox.md) — which RHEL 9 guest image the Proxmox Terraform flow expects and how to provide it
- [docs/02-aap-single-node.md](docs/02-aap-single-node.md) — optional single-node Ansible Automation Platform reference
- [docs/03-edge-manager-rhacm.md](docs/03-edge-manager-rhacm.md) — alternate Edge Manager deployment through Red Hat Advanced Cluster Management
