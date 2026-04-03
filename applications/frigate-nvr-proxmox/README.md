# frigate-nvr-proxmox

This is a Proxmox-targeted copy of the `frigate-nvr` example application. It keeps the same Frigate deployment pattern, persistent storage layout, and config sync model, but uses a distinct fleet name and image naming so it can be driven independently.

> **NOTE:** Frigate is an open source third party application, not a supported Red Hat application. This is for demo purposes only.

## Creating the Base Image

This bootc image prepares a secondary disk on `/dev/sdb` for Frigate data storage and enables remote access through a `cloud-user` account with your authorized SSH key.

The bootc Containerfile in this variant installs `open-vm-tools` rather than `qemu-guest-agent`, matching your requested guest-agent change. Before building, put an SSH public key into `bootc/demo-authorized-key.pub`.

### Build and Publish the bootc container

```bash
cd applications/frigate-nvr-proxmox/bootc
podman build --platform linux/amd64 -t quay.io/bpandey/rhem:frigate-proxmox-v1 .
podman login quay.io
podman push quay.io/bpandey/rhem:frigate-proxmox-v1
```

### Create a Proxmox device VM

This app also includes a small Terraform wrapper in [terraform](/Users/bkpandey/Documents/workspace/code/redhat-edge-manager/applications/frigate-nvr-proxmox/terraform) to create one device VM from a built bootc qcow2 with very few required settings.

```bash
cd applications/frigate-nvr-proxmox/terraform
cp terraform.tfvars.example terraform.tfvars
cp .env.example .env
./tf.sh init
./tf.sh apply
```

The only values you normally need to set in `terraform.tfvars` are:

- `proxmox_endpoint`
- `proxmox_node`
- `disk_storage`
- `bootc_qcow2_path`
- `vm_id`
- `vm_name`

This wrapper creates:

- one bootc VM
- one extra secondary disk on `scsi1` for Frigate storage
- a Proxmox guest agent enabled VM definition

## Deploy App and Configuration

The VM should have at least two disks:

- the primary disk built from this bootc image
- a blank secondary disk exposed as `/dev/sdb` for Frigate storage

### Apply the configs

```bash
flightctl login
flightctl apply -f applications/frigate-nvr-proxmox/repository.yaml
flightctl apply -f applications/frigate-nvr-proxmox/resourcesync.yaml
```
