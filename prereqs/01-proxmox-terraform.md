# Proxmox and RHEL 9 guest image reference

Use this page if you want this repo to create RHEL 9 virtual machines on Proxmox.

If you are following the labs manually on your own hosts, you can usually skip this page and start with [`README.md`](../README.md) or [`automation/README.md`](../automation/README.md).

## What this repo expects

The Proxmox Terraform environments under [`automation/terraform/environments/`](../automation/terraform/environments/) create RHEL 9 virtual machines by:

- using a RHEL 9 KVM guest image in `.qcow2` format
- injecting cloud-init settings
- configuring CPU, memory, disk, and networking
- optionally generating Ansible inventory for the automation flow

The main entry points are:

- `make up` / `make down` for the full automated stack
- `make rhel-vms-up` / `make rhel-vms-down` for the base RHEL VMs only
- `make create-rhel9 ROLE=<role>` for one extra RHEL VM

## Before you run

Have these ready:

1. A reachable Proxmox API endpoint
2. Proxmox API credentials
3. Free VM IDs and IP addresses for your environment
4. A RHEL 9 KVM guest image available to Proxmox

For credentials, provide either:

- `PROXMOX_VE_API_TOKEN`
- or `PROXMOX_VE_USERNAME` and `PROXMOX_VE_PASSWORD`

If your Proxmox API uses a self-signed certificate, set:

```bash
PROXMOX_VE_INSECURE=true
```

The repo reads those values from the environment-specific `.env` files under `automation/terraform/environments/`, or from your shell environment.

## Use the correct RHEL image

This repo expects the RHEL 9 KVM guest image, not the boot ISO.

From the Red Hat downloads page, download:

- RHEL 9
- `x86_64`
- `KVM Guest Image`
- file type: `.qcow2`

Do not use:

- `boot.iso`
- `dvd.iso`
- installer media in general

## Make the guest image available to Proxmox

You have two supported options.

### Option 1: Upload the qcow2 manually

This is the simplest path.

1. Download the RHEL 9 KVM guest image from Red Hat.
2. Upload the `.qcow2` to the Proxmox storage used for imports.
3. Set `cloud_image_import_id` in `terraform.tfvars` to the exact Proxmox volume ID.

Typical example:

```hcl
cloud_image_import_id = "local:import/rhel9-guest-image.qcow2"
ci_user               = "cloud-user"
```

The value must match what Proxmox shows in storage content.

If Terraform fails with a disk import or `failed to stat` error, the usual cause is that the uploaded file name and `cloud_image_import_id` do not match.

### Option 2: Let Proxmox download the image

You can also set a direct download URL:

```hcl
cloud_image_download_url = "https://example.com/path/to/rhel-9-guest.qcow2"
```

Use this only when the Proxmox node can fetch the file without interactive login.

This does not work with the normal Red Hat customer portal download flow unless you provide a direct URL that Proxmox can access non-interactively.

If you use this path:

- `cloud_image_import_datastore_id` must point to storage that allows `Import`
- the Proxmox API user needs the datastore permissions required by the provider
- large downloads may need a higher `cloud_image_download_timeout_seconds`

## Common files to edit

For the full demo stack:

- `automation/terraform/environments/demo/.env`
- `automation/terraform/environments/demo/terraform.tfvars`

For the base RHEL VM path:

- `automation/terraform/environments/manual-demo/.env`
- `automation/terraform/environments/manual-demo/terraform.tfvars`

For a single extra RHEL VM:

- the command-line arguments you pass to `make create-rhel9`

Pick free `vm_id` values and valid IP settings before you apply.

## Common commands

```bash
make init-files
make plan
make up
make down
```

If you want to work directly in one Terraform environment:

```bash
cd automation/terraform/environments/demo
terraform init
./tf.sh plan
./tf.sh apply
```

## Common problems

| Issue | What to check |
|--------|---------------|
| Proxmox credentials not found | Confirm the environment `.env` file or shell exports are set correctly. |
| Guest image import fails | Confirm the qcow2 exists in Proxmox storage and `cloud_image_import_id` matches the exact volume ID. |
| Proxmox cannot download the image | Confirm the URL is directly reachable from the Proxmox node without interactive login. |
| VM boots without network | Confirm the configured bridge exists and the IP settings are valid for your network. |
| Guest agent warnings | Install `qemu-guest-agent` in the guest image or guest OS and reboot if needed. |
