# Reference Notes

Most users should start at the repo root [README.md](../README.md).

Use `prereqs/` only when you need supporting information that sits outside the main lab flow, such as infrastructure setup notes or an alternate deployment path.

## When to use this directory

Open one of these pages if you need:

- guidance for the Proxmox-based automation environment
- help preparing the RHEL guest image used by the Terraform workflow
- notes for the optional Ansible Automation Platform host
- the alternate Edge Manager deployment path through RHACM

If you are following the manual product labs, you can usually skip this directory and stay in [`labs/`](../labs/).

If you want the repo to create and configure the demo environment for you, start with [`automation/README.md`](../automation/README.md).

## Pages

- [01-proxmox-terraform.md](01-proxmox-terraform.md) — how the Proxmox automation path works and what to configure before you run it
- [rhel-guest-image-proxmox.md](rhel-guest-image-proxmox.md) — which RHEL 9 guest image the Proxmox Terraform flow expects and how to provide it
- [02-aap-single-node.md](02-aap-single-node.md) — optional single-node Ansible Automation Platform reference
- [03-edge-manager-rhacm.md](03-edge-manager-rhacm.md) — alternate Edge Manager deployment through Red Hat Advanced Cluster Management
