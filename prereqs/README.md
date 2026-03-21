# Prerequisites (Proxmox RHEL 9 + network; optional AAP)

- **Terraform** — **RHEL 9** cloud image VM in pool **`rhem-eap-prereq`**, **static IP + DNS + search domain** via cloud-init (habitvillage-style `vmbr0` / `192.168.4.0/22`). Upload qcow2 first: [docs/rhel-guest-image-proxmox.md](docs/rhel-guest-image-proxmox.md). From repo root: **`make tf-up`** / **`make tf-down`**. Set **`PROXMOX_VE_API_TOKEN`** or **`PROXMOX_VE_USERNAME` + `PROXMOX_VE_PASSWORD`**, or put them in **`prereqs/terraform/.env`** (see `.env.example`). Details: [docs/01-proxmox-terraform.md](docs/01-proxmox-terraform.md), [network-habitvillage-parity.md](docs/network-habitvillage-parity.md). **Do not** change habitvillage VMs.  
- **Red Hat Edge Manager** — not automated here; when you are ready, continue with [Lab 1](../labs/01-edge-manager-installation/lab.md) and the [product install guide](https://docs.redhat.com/en/documentation/red_hat_edge_manager/1.0/html/installing_red_hat_edge_manager_on_red_hat_enterprise_linux/).  
- **AAP** (optional) — [docs/02-aap-single-node.md](docs/02-aap-single-node.md).  
- **RHEM via RHACM** (alternate) — [docs/03-edge-manager-rhacm.md](docs/03-edge-manager-rhacm.md).

## Order

0. [docs/00-scope.md](docs/00-scope.md)  
1. [docs/01-proxmox-terraform.md](docs/01-proxmox-terraform.md) + [network-habitvillage-parity.md](docs/network-habitvillage-parity.md) — **RHEL 9 VM + network**  
2. [docs/02-aap-single-node.md](docs/02-aap-single-node.md) — if using AAP  
3. [Lab 1](../labs/01-edge-manager-installation/lab.md) — **install RHEM on the RHEL VM**  
4. [docs/03-edge-manager-rhacm.md](docs/03-edge-manager-rhacm.md) — only if using OpenShift/RHACM  

**Ansible:** `cp ansible/group_vars/all.yml.example ansible/group_vars/all.yml` (gitignored) — AAP / RHACM helpers only.

## Layout

| Path | Purpose |
|------|---------|
| `terraform/` | Proxmox RHEL 9 VM + dedicated pool + cloud-init network |
| `ansible/` | AAP, optional RHACM `oc patch` |
| `docs/` | Short guides + Red Hat links |

## Credentials

Use `terraform.tfvars` (gitignored) or provider env vars (`PROXMOX_VE_*`). Do not commit secrets.

### habitvillage (no-touch rule)

- Terraform **must not** reference habitvillage **pool members** or edit those VMs.  
- Using node name **`habitvillage`** only selects the **hypervisor** to place *new* disks/VMs.  
- Defaults **mirror** observed network/DNS from a habitvillage k3s sample; search domain is **`rhem-eap.lan`** so resolv.conf does not use `habitvillage.lan`.

## Resource expectations

Terraform defaults target a **general RHEL 9** guest. For **RHEM** on that same host, Red Hat recommends **4 vCPU / 16 GB RAM** — raise `vm_cores`, `vm_memory_mb`, and `vm_disk_gb` in `terraform.tfvars` before apply (see [Lab 1](../labs/01-edge-manager-installation/lab.md)).
