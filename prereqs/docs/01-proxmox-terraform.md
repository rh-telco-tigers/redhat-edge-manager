# Proxmox automation reference

Use this page only if you are using the supported Proxmox-based automation path. Manual lab readers do not need this document.

The supported entry points are described in [`automation/README.md`](../../automation/README.md).

## What the Proxmox Terraform path does

The Terraform environments under [`automation/terraform/environments/`](../../automation/terraform/environments/) create RHEL 9 virtual machines on Proxmox by:

- cloning from a RHEL 9 KVM guest image
- injecting cloud-init user data
- configuring CPU, memory, disk, and networking
- optionally generating inventory for the Ansible automation path

Supported entry points:

- `make up` / `make down` for the full automated stack
- `make rhel-vms-up` / `make rhel-vms-down` for the base manual-lab VMs
- `make create-rhel9 ROLE=<role>` for a single-purpose RHEL VM

## Before you run

1. Make sure you have a reachable Proxmox API endpoint.
2. Provide either `PROXMOX_VE_API_TOKEN` or `PROXMOX_VE_USERNAME` and `PROXMOX_VE_PASSWORD`.
3. Set `PROXMOX_VE_INSECURE=true` if your Proxmox API uses a self-signed certificate.
4. Make sure the target environment `.env` and `terraform.tfvars` files are filled in under `automation/terraform/environments/`.
5. Make sure Proxmox can access the RHEL 9 KVM guest image you plan to use. See [rhel-guest-image-proxmox.md](rhel-guest-image-proxmox.md).

Provider: [bpg/proxmox](https://registry.terraform.io/providers/bpg/proxmox/latest/docs)

## Common commands

```bash
make init-files
make plan
make up
make down
```

For Terraform-only work inside one environment:

```bash
cd automation/terraform/environments/demo
terraform init
./tf.sh plan
./tf.sh apply
```

## What to edit

The most common files are:

- `automation/terraform/environments/demo/.env`
- `automation/terraform/environments/demo/terraform.tfvars`
- `automation/terraform/environments/manual-demo/.env`
- `automation/terraform/environments/manual-demo/terraform.tfvars`

Pick free `vm_id` values and valid IPs for your network before you apply.

## Troubleshooting

| Issue | Action |
|--------|--------|
| Provider says no credentials were supplied | Set Proxmox API credentials in the shell or in the environment-local `.env` file. |
| Disk import fails | Confirm the qcow2 exists in Proxmox storage and that `cloud_image_import_id` matches the actual volume ID. |
| VM boots without network | Confirm the configured bridge exists on the Proxmox node and that the selected IP settings are valid. |
| Guest agent warnings | Install `qemu-guest-agent` in the guest and restart the VM if needed. |
