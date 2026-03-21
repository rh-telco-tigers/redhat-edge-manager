# Step 1 — Proxmox VMs (automation Terraform)

## Before you run

1. **Resource pool** — the automation creates a dedicated project pool and only manages VMs inside that pool. It does **not** add/remove members of the **habitvillage** pool or edit habitvillage VMs.
2. **Network & storage** — Defaults mirror a habitvillage k3s node ( **`vmbr0`**, **`192.168.4.0/22`**, gateway **`192.168.4.1`**, DNS **`192.168.4.220`** + forwarders). See [network-habitvillage-parity.md](network-habitvillage-parity.md). Pick an **unused** `ipv4_cidr`.
3. **Cloud image** — **RHEL 9 KVM guest** qcow2 as **`local:import/rhel9-guest-image.qcow2`** (see [rhel-guest-image-proxmox.md](rhel-guest-image-proxmox.md)). User **`cloud-user`**.
4. **Auth** — `PROXMOX_VE_API_TOKEN` **or** `PROXMOX_VE_USERNAME` + `PROXMOX_VE_PASSWORD` (passwords with `%` need URL-encoding when testing with curl).
5. **SSH public key** — In `terraform.tfvars`.

Provider: [bpg/proxmox](https://registry.terraform.io/providers/bpg/proxmox/latest/docs).

## Steps

From the **repo root** (after `make init-files` and editing `automation/terraform/environments/demo/terraform.tfvars`):

**Credentials** (the provider error *“must provide either username and password, an API token, or a ticket”* means none of these were set):

- **Option A — shell:** `export PROXMOX_VE_API_TOKEN='user@pam!id=secret'` *or* `export PROXMOX_VE_USERNAME='root@pam'` and `export PROXMOX_VE_PASSWORD='...'`
- **Option B — file:** `make init-files`, then edit `automation/terraform/environments/demo/.env` (`.env` is gitignored). `make up` runs the environment-local `tf.sh`, which sources `.env` automatically.

Also set `export PROXMOX_VE_INSECURE=true` when using the default self-signed PVE cert (or put it in `.env`).

```bash
make plan   # optional preview
make up     # create demo VMs, then run Ansible automation
make down   # destroy the demo VMs
```

Or manually:

```bash
cd automation/terraform/environments/demo
terraform init
./tf.sh plan
./tf.sh apply
```

## After apply

- SSH: `ssh <ci_user>@<ipv4_cidr address>` (static) or check Proxmox **Summary** if using DHCP.
- Install **qemu-guest-agent** in the guest if the provider warns about the agent.

## Sizing

The demo environment defines separate sizing for DNS, RHEM, Keycloak, and AAP in `automation/terraform/environments/demo/terraform.tfvars`. Adjust those values before `make up`.

## Troubleshooting

| Issue | Action |
|--------|--------|
| Disk import fails | Confirm `cloud_image_import_id` exists under **node → local → import**. |
| `failed to stat '/var/lib/vz/import/....qcow2'` | The qcow2 is not on the node at that path. Upload the [RHEL KVM guest image](rhel-guest-image-proxmox.md), **or** set `cloud_image_import_id` in `terraform.tfvars` to the exact **volid** from **Storage → local → Content** (filename must match what you uploaded). |
| Wrong NIC / no IP | Confirm `network_bridge = "vmbr0"` matches the node. |
| Static IP clash | Change `ipv4_cidr` to a free address in `/22`. |
