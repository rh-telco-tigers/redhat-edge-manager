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

`make bootc-build` builds the early-bound bootc image on the RHEM host, pushes it to Satellite by default, and fetches the installer artifacts back to `automation/artifacts/bootc/`.

`make approve-enrollment` approves pending device enrollment requests by using `flightctl` on the RHEM host.

`make device-vm-up` creates a blank Proxmox device VM, uploads the generated installer ISO, and boots the VM through the same unattended installer flow described in the manual labs.

`make fleet-apply` creates or updates the demo Edge Manager fleet that points at the Satellite-hosted bootc image.

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
- builds the image and pushes it to Satellite
- stages the same image into local container storage and uses `bootc-image-builder --local`
- runs `bootc-image-builder` for the unattended installer ISO and also fetches the optional `qcow2`
- fetches the generated artifacts back to this repo

By default the fetched artifacts land here:

```text
automation/artifacts/bootc/rhem-prereq-rhel-01/install.iso
automation/artifacts/bootc/rhem-prereq-rhel-01/disk.qcow2
```

`make device-vm-up` uses the fetched `install.iso` artifact to create one fresh demo device VM on Proxmox with a blank disk. That keeps the automated device path aligned with the manual lab.

`make approve-enrollment` can also wait until a pending request exists:

```bash
WAIT_FOR_PENDING=true make approve-enrollment
```

`make fleet-apply` creates a `Fleet` resource that selects devices labeled `fleet=demo` and points them at the same Satellite image reference used in Lab 3.

If you want the repo to run the practical Labs 3 to 5 path in one shot, use:

```bash
make device-demo
```

If you need to rebuild the installer after changing the bootc build inputs, force a new image and ISO build:

```bash
BOOTC_FORCE_REBUILD=true make bootc-build
```

If your environment needs installer-time DNS overrides, enable the optional Kickstart-backed installer config in `automation/ansible/group_vars/all.yml` by setting:

- `bootc_installer_config_enabled: true`
- `bootc_installer_nameservers`

If you want signed pushes to an OCI registry instead of the default Satellite path, set these in `automation/ansible/group_vars/all.yml` first:

- `bootc_image_repo`
- `bootc_publish_enabled: true`
- `bootc_registry`
- `bootc_registry_username`
- `bootc_registry_password`
- `bootc_sign_with_sigstore: true`
