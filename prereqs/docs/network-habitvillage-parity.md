# Network & storage parity (read-only reference)

This stack **does not** change Proxmox **node** networking, **bridges**, or any **habitvillage** VM. It only creates resources in pool **`rhem-eap-prereq`**.

## What we copied from an existing habitvillage node (VM 311 sample)

| Setting | habitvillage k3s node example | This project (Terraform defaults) |
|--------|--------------------------------|-------------------------------------|
| Bridge | `vmbr0`, virtio NIC, firewall off | Same |
| L3 | `gw=192.168.4.1`, `ip=…/22` | `ipv4_gateway`, `ipv4_cidr` `/22` |
| DNS servers | `192.168.4.220`, `1.1.1.1`, `8.8.8.8` | Same list |
| Search domain | `habitvillage.lan` | **`rhem-eap.lan`** (separate; avoids mixing search paths) |
| Root disk | `local-zfs`, scsi, discard, iothread, ssd | Same pattern |
| CPU model | `x86-64-v2-AES` | Same default |

## Storage layout on this host (observed)

| ID | Role | Use for this project |
|----|------|----------------------|
| `local` | ISO / import / templates | Source qcow2: `local:import/...` |
| `local-zfs` | VM images (zfspool) | VM disks + cloud-init snippets |

## Before you apply static IP

1. Pick an **unused** address in `192.168.4.0/22` (default `192.168.4.240/22` is only an example).  
2. If you switch an existing VM from DHCP → static, expect a **cloud-init / network** refresh (reboot may be needed inside the guest).

## Do not touch habitvillage

- Do **not** move habitvillage VMs into `rhem-eap-prereq`.  
- Do **not** edit habitvillage VM configs from this Terraform workspace.  
- Node name `habitvillage` is only the **Proxmox hypervisor**; your new VM runs *on* that node but is **not** part of the habitvillage Kubernetes project.
