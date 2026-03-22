# Automation

`labs/` are the manual walkthroughs. `automation/` is the runnable path for the demo environment.

## What lives here

- `terraform/` creates the management VMs on Proxmox.
- `ansible/` configures the management stack on those VMs.
- `scripts/` bootstraps local files and wraps common tasks.

## Current scope

`make up` uses the demo Terraform environment plus the Ansible site playbook to:

- create the demo VM set from `automation/terraform/environments/demo/terraform.tfvars`
- configure PowerDNS for the lab zone
- install Red Hat Edge Manager on the RHEM VM
- install Keycloak in Podman and switch RHEM to external OIDC
- install Red Hat Satellite on a dedicated Satellite VM
- optionally install AAP when `aap_install_enabled: true`

`make down` destroys the Terraform-managed demo VMs.

`make create-rhel9` provisions one standalone RHEL 9 VM using role-based defaults.

`make up` bootstraps a repo-local Ansible environment in `automation/.venv` automatically, so you do not need a separate global `ansible-playbook` install on your Mac.

`make bootc-build` builds the early-bound bootc image on the RHEM host, pushes it to Satellite by default, and fetches the bootable qcow2 disk image back to `automation/artifacts/bootc/`.

`make approve-enrollment` approves pending device enrollment requests by using `flightctl` on the RHEM host.

`make device-vm-up` uploads the generated bootable qcow2 disk image to Proxmox, creates a fresh device VM, and boots the VM directly from that imported disk.

`make fleet-apply` creates or updates the demo Edge Manager fleet that points at the Satellite-hosted bootc image.

`make app-build` builds two application images on the RHEM host:

- the runtime image the device actually runs
- the small quadlet package image that Edge Manager references in the fleet

`make app-deploy` updates the demo fleet so Edge Manager deploys that application package to the enrolled device and waits for the application to report `Running`.

## Full automation

Use this when you want Terraform plus Ansible to stand up the fully automated stack.

1. Create the local files:

```bash
make init-files
```

This also creates a dedicated SSH keypair for the demo at `~/.ssh/redhat-edge-manager-demo` if it does not already exist, and the Terraform examples use `~/.ssh/redhat-edge-manager-demo.pub`.

2. Edit:

- `automation/terraform/environments/demo/terraform.tfvars`
- `automation/ansible/group_vars/all.yml`

Pick free `vm_id` values and unused IPs in `automation/terraform/environments/demo/terraform.tfvars`. The demo environment treats those VM IDs as Terraform-owned and may replace an existing VM if you point it at an ID that is already in use.

In `automation/ansible/group_vars/all.yml`, set one RHSM auth method before running `make up`:

- `rhsm_username` and `rhsm_password`, or
- `rhsm_org` and `rhsm_activation_key`

If `registry_redhat_io_username` and `registry_redhat_io_password` are left blank, the automation reuses the RHSM username and password for `registry.redhat.io`.

3. Run:

```bash
make up
```

If Terraform already succeeded and you only need to retry the Ansible phase, run:

```bash
make configure
```

4. Tear down:

```bash
make down
```

## Manual demo VMs

Use this when you want the labs to stay manual, but you still want Terraform to create the base RHEL VMs for Edge Manager and Keycloak.

1. Create the local files:

```bash
make init-files
```

2. Edit:

- `automation/terraform/environments/manual-demo/terraform.tfvars`

The manual demo environment is Terraform-only. It does not run Ansible, and it currently creates only the RHEM and Keycloak RHEL 9 VMs for Labs 1 and 2.

If you need an additional standalone VM for a later manual lab, such as a dedicated Satellite host, use `make create-rhel9`.

3. Run:

```bash
make rhel-vms-up
```

4. Tear down:

```bash
make rhel-vms-down
```

## First run
Use either the full automation path above or the manual-demo Terraform-only path, depending on whether you want the repo to configure services for you or whether you want to walk the labs by hand.

## Single VM helper

Examples:

```bash
make create-rhel9 ROLE=keycloak VM_ID=121 IPV4_CIDR=192.168.4.121/22
make create-rhel9 ROLE=edge-manager VM_ID=122 IPV4_CIDR=192.168.4.122/22 VM_NAME=rhem-lab-02 DNS_NAME=rhem02
make create-rhel9 ROLE=satellite VM_ID=123 IPV4_CIDR=192.168.4.123/22
```

Accepted `ROLE` presets:

- `edge-manager`
- `keycloak`
- `satellite`
- `dns`
- `aap`
- `generic`

Use `ROLE=satellite` only for a fresh, dedicated VM. Do not install Satellite on the existing Edge Manager or Keycloak hosts.

Optional make variables:

- `VM_NAME`
- `DNS_NAME`
- `VM_CORES`
- `VM_MEMORY_MB`
- `VM_DISK_GB`
- `IPV4_MODE=dhcp`
- `IPV4_CIDR`
- `IPV4_GATEWAY`
- `DNS_SERVERS=192.168.4.30,1.1.1.1`
- `VM_TAGS=service-demo,owner-bk`
- `ACTION=plan|apply|destroy`

## Device image helpers

Use these after `make up` when you want the end-to-end Labs 3, 4, and 5 flow:

```bash
make bootc-build
make device-vm-up
make approve-enrollment
make fleet-apply
```

`make bootc-build` does the following on the RHEM host:

- logs in to Edge Manager with the lab admin account
- requests an early-binding enrollment config
- prepares a Satellite registry path for the bootc image
- renders a real bootc Containerfile with `flightctl-agent`
- embeds the Satellite CA into the image
- leaves Podman available in the device OS image for the later application-management lab
- seeds a demo `cloud-user` with the local repo SSH key
- builds the image and pushes it to Satellite
- stages the same image into local container storage and uses `bootc-image-builder --local`
- runs `bootc-image-builder` for the bootable qcow2 disk image
- fetches the generated artifacts back to this repo

By default the fetched artifacts land here:

```text
automation/artifacts/bootc/rhem-prereq-rhel-01/disk.qcow2
```

If you explicitly want the optional ISO as well:

```bash
BOOTC_BUILD_ISO=true BOOTC_FETCH_ISO=true make bootc-build
```

`make device-vm-up` uses the fetched `disk.qcow2` artifact to create one fresh demo device VM on Proxmox from the bootable disk image. That keeps the VM demo aligned with the practical "boot the OS disk image" workflow instead of simulating a manual install.

The demo device image includes the local `~/.ssh/redhat-edge-manager-demo.pub` key for `cloud-user`, so you can inspect the running device over SSH if needed.

`make approve-enrollment` can also wait until a pending request exists:

```bash
WAIT_FOR_PENDING=true make approve-enrollment
```

`make fleet-apply` creates a `Fleet` resource that selects devices labeled `fleet=demo` and points them at the same Satellite image reference used in Lab 3.

If you want the repo to run the practical Labs 3 to 5 path in one shot, use:

```bash
make device-demo
```

`make device-demo` uses the same qcow2-first path as `make bootc-build`.

## Application helpers

Use these after the device is already online and selected by `Fleet/demo`:

```bash
make app-build
make app-deploy
```

`make app-build` pushes the default `hello-web` demo application into Satellite:

- `hello-web-runtime:v3`
- `hello-web-package:v3`

The package image uses a quadlet wrapper, so Edge Manager manages one container from an `application.container` file while Satellite continues to host both the runtime image and the wrapper image.

Both images land in the same Satellite product family used by the earlier device image flow unless you override the app repository names in `automation/ansible/group_vars/all.yml`.

`make app-deploy` updates `Fleet/demo` so the selected device keeps the same OS image and now also gets:

- application name `hello-web`
- application image `satellite.../hello-web-package:v3`

If you want the repo to run the practical Lab 6 path in one shot after Labs 3 to 5 are complete, use:

```bash
make app-demo
```

If you need to rebuild the artifacts after changing the bootc build inputs, force a new image and qcow2 build:

```bash
BOOTC_FORCE_REBUILD=true make bootc-build
```

The optional ISO path uses a minimal Kickstart-backed installer config so the device can install non-interactively and reboot out of the ISO. If you enable that path and need different installer-time DNS, adjust:

- `bootc_installer_nameservers`

If you want to disable that automation and handle the installer manually, set:

- `bootc_installer_config_enabled: false`

If you want signed pushes to an OCI registry instead of the default Satellite path, set these in `automation/ansible/group_vars/all.yml` first:

- `bootc_image_repo`
- `bootc_publish_enabled: true`
- `bootc_registry`
- `bootc_registry_username`
- `bootc_registry_password`
- `bootc_sign_with_sigstore: true`
