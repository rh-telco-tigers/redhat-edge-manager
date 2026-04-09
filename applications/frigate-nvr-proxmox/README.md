# frigate-nvr-proxmox

This is a Proxmox-targeted copy of the `frigate-nvr` example application. It keeps the same Frigate deployment pattern, persistent storage layout, and config sync model, but uses a distinct fleet name and image naming so it can be driven independently.

> **NOTE:** Frigate is an open source third party application, not a supported Red Hat application. This is for demo purposes only.

## Creating the Base Image

This bootc image prepares a secondary disk on `/dev/sdb` for Frigate data storage and enables remote access through a `cloud-user` account with your authorized SSH key.

The bootc Containerfile in this variant installs `open-vm-tools` rather than `qemu-guest-agent`, matching requested guest-agent change. Before building, put an SSH public key into `bootc/demo-authorized-key.pub`.

### Build and Publish the bootc container

Run this on a registered RHEL 9 host with access to `registry.redhat.io`.

```bash
cd applications/frigate-nvr-proxmox/bootc
podman login registry.redhat.io
podman build -t quay.io/bpandey/rhem:frigate-proxmox-v1 .
podman login quay.io
podman push quay.io/bpandey/rhem:frigate-proxmox-v1
```

### Build the qcow2 image

Generate the qcow2 on the same RHEL host. `bootc-image-builder` needs access to the local container storage on that Linux system.

```bash
cd applications/frigate-nvr-proxmox/bootc
podman login registry.redhat.io
podman tag quay.io/bpandey/rhem:frigate-proxmox-v1 localhost/frigate-proxmox:v1
mkdir -p output
podman pull registry.redhat.io/rhel9/bootc-image-builder:latest

podman run --rm -it --privileged --pull=never \
  --security-opt label=type:unconfined_t \
  -v /var/lib/containers/storage:/var/lib/containers/storage \
  -v "${PWD}/output":/output \
  registry.redhat.io/rhel9/bootc-image-builder:latest \
  --type qcow2 \
  localhost/frigate-proxmox:v1
```

The resulting qcow2 will be written under `applications/frigate-nvr-proxmox/bootc/output/`. Point `bootc_qcow2_path` in the Terraform folder at that file before running Terraform.

### Create the cloud-init enrollment payload

This image is intended to use late binding through cloud-init. After the qcow2 is built, manually request the enrollment config from Edge Manager and render the cloud-init file that will be attached to the VM on first boot.

```bash
cd applications/frigate-nvr-proxmox/bootc
flightctl certificate request --signer enrollment --expiration 365d --output embedded > config.yaml
cp user-data-template.yaml user-data.rendered.yaml
```

Open `config.yaml`, copy its full contents, then paste that content into `user-data.rendered.yaml` where `CHANGEME_PASTE_CONFIG_YAML_HERE` appears. Keep the pasted lines indented under `content: |`.

Because this setup does not have DNS, also replace:

- `CHANGEME_RHEM_HOSTNAME` with the Edge Manager hostname from `config.yaml`
- `CHANGEME_RHEM_HOSTS_LINE` with the matching `/etc/hosts` entry

Example:

```text
192.168.4.120 rhem-manual-rhel-01.rhem-eap.lan rhem-manual
```

This keeps the certificate request manual while still using cloud-init for first-boot enrollment.

### Create a Proxmox device VM

This app also includes a small Terraform wrapper in `applications/frigate-nvr-proxmox/terraform` to create one device VM from a built bootc qcow2 with very few required settings. If you set `cloud_init_user_data_path`, Terraform uploads that rendered cloud-init file and attaches it to the VM.

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
- `cloud_init_user_data_path`
- `vm_id`
- `vm_name`

This wrapper creates:

- one bootc VM
- one extra secondary disk on `scsi1` for Frigate storage
- an optional attached cloud-init user-data snippet for enrollment
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
