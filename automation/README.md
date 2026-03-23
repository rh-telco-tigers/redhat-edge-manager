# Automation

This folder contains the runnable automation for this repo.

Use it when you want the repo to create and configure the demo environment for you instead of following the product labs by hand.

## What this automation covers

The full automation path can:

- create the management VMs on Proxmox
- configure DNS for the demo domain
- install Red Hat Edge Manager on RHEL
- install Keycloak and connect Edge Manager to it, or switch Edge Manager to AAP authentication
- install Red Hat Satellite
- optionally install Ansible Automation Platform
- build the bootc device image
- create a demo device VM from that image
- approve device enrollment
- create the demo fleet
- build and deploy the demo application

## Before you start

Have these ready before your first run:

- access to a Proxmox server
- a RHEL 9 KVM guest image available to Proxmox
- Red Hat subscription credentials for RHEL registration
- `registry.redhat.io` credentials, or RHSM credentials that can also be used there
- a machine with `python3` available locally

If you are using the full automation path, also make sure you have enough free IPs and VM IDs for the management VMs.

If you need details about the Proxmox image requirement, see [../prereqs/01-proxmox-terraform.md](../prereqs/01-proxmox-terraform.md).

## Main workflows

### Full demo environment

Use this when you want the repo to build and configure the whole management stack.

1. Initialize local config files:

```bash
make init-files
```

2. Edit these files:

- `automation/terraform/environments/demo/.env`
- `automation/terraform/environments/demo/terraform.tfvars`
- `automation/ansible/group_vars/all.yml`

3. Run the full stack:

```bash
make up
```

Useful related commands:

- `make plan` — preview Terraform changes for the full stack
- `make configure` — rerun only the Ansible configuration phase
- `make down` — destroy the full stack, including device VMs created through `make device-vm-up`

What `make up` installs by default:

- PowerDNS
- Red Hat Edge Manager
- Keycloak
- Red Hat Satellite

AAP is optional and is only installed when `aap_install_enabled: true` is set in `automation/ansible/group_vars/all.yml`.

Put your Proxmox API credentials in `automation/terraform/environments/demo/.env`, or export them in your shell before you run `make up`.

The default auth path is Keycloak. If you want the full automation path to use AAP authentication instead, set these in `automation/ansible/group_vars/all.yml` before you run `make up`:

- `rhem_auth_provider: aap`
- `aap_install_enabled: true`
- `aap_bundle_tar: /path/to/your/aap-setup-bundle.tar.gz`
- `aap_admin_password: CHANGEME-aap-admin-password`

Leave `aap_oauth_application_client_id` empty if you want Edge Manager to create the OAuth application automatically by using a write-scoped AAP token. The automation will generate that token through the AAP gateway API by default.

If your AAP deployment needs a non-default token endpoint, set `aap_token_api_url`. The default token endpoint used by the automation is `https://127.0.0.1/api/gateway/v1/tokens/` on the AAP host.

### Base RHEL VMs only

Use this when you want the labs to stay manual, but you still want Terraform to create the base RHEL VMs for Edge Manager and Keycloak.

1. Initialize local config files:

```bash
make init-files
```

2. Edit:

- `automation/terraform/environments/manual-demo/.env`
- `automation/terraform/environments/manual-demo/terraform.tfvars`

3. Create the VMs:

```bash
make rhel-vms-up
```

4. Remove them later if needed:

```bash
make rhel-vms-down
```

This path is Terraform-only. It does not install or configure services inside those VMs.

Put your Proxmox API credentials in `automation/terraform/environments/manual-demo/.env`, or export them in your shell before you run `make rhel-vms-up`.

### One standalone RHEL VM

Use this when you need one extra host, for example a dedicated Satellite host.

Examples:

```bash
make create-rhel9 ROLE=keycloak VM_ID=121 IPV4_CIDR=192.168.4.121/22
make create-rhel9 ROLE=edge-manager VM_ID=122 IPV4_CIDR=192.168.4.122/22 VM_NAME=rhem-lab-02 DNS_NAME=rhem02
make create-rhel9 ROLE=satellite VM_ID=123 IPV4_CIDR=192.168.4.123/22
```

Supported `ROLE` presets:

- `edge-manager`
- `keycloak`
- `satellite`
- `dns`
- `aap`
- `generic`

## AAP helpers

Use these when you want to install or integrate Ansible Automation Platform separately from the rest of the stack.

### Install AAP on the AAP host

```bash
make aap-install
```

This uses `automation/ansible/playbooks/aap_install.yml`.

### Configure Edge Manager to use AAP authentication

```bash
make aap-integrate
```

This uses `automation/ansible/playbooks/aap_integration.yml`.

### Run both steps together

```bash
make aap-setup
```

If you want the AAP integration path, set `rhem_auth_provider: aap` in `automation/ansible/group_vars/all.yml` first.

If you leave `aap_oauth_application_client_id` empty, this path uses a write-scoped AAP token and lets Edge Manager create the OAuth application automatically.

## Device workflow helpers

Use these after the management stack is already up.

### Build the device image

```bash
make bootc-build
```

This builds the early-binding bootc image on the Edge Manager host, pushes it to Satellite by default, and fetches the generated artifacts back to this repo.

To build the late-binding variant instead:

```bash
make bootc-build-latebinding
```

That late-binding build fetches both:

- the clean `disk.qcow2`
- the matching `cloud-init.user-data.yaml`

The source of truth for this flow lives under:

```text
bootc/earlybinding/
bootc/latebinding/
```

Fetched artifacts are stored under:

```text
automation/artifacts/bootc/earlybinding/<rhem-host>/
automation/artifacts/bootc/latebinding/<rhem-host>/
automation/artifacts/bootc/current/<rhem-host>/
```

`current/` always points to the most recent bootc build and is what `make device-vm-up` uses by default.

Optional ISO build:

```bash
BOOTC_BUILD_ISO=true BOOTC_FETCH_ISO=true make bootc-build
```

Force a rebuild:

```bash
BOOTC_FORCE_REBUILD=true make bootc-build
```

### Create the demo device VM

```bash
make device-vm-up
```

This uses the latest fetched `disk.qcow2` artifact from `automation/artifacts/bootc/current/` and creates one fresh demo device VM on Proxmox.

If the current artifact is early-binding, the image already contains the enrollment configuration.

If the current artifact is late-binding, `make device-vm-up` uploads the clean qcow2 and attaches the generated cloud-init user-data so the device receives the enrollment config and Satellite registry CA at first boot.

If you want to create additional named devices on the fly, pass a device name and optional site:

```bash
make device-vm-up name=database site=homelab
make device-vm-up name=storefront site=branch-west VM_CORES=4 VM_MEMORY_MB=8192
```

You can also attach device label metadata that will be reused during enrollment approval:

```bash
make device-vm-up name=database site=homelab env=lab role=db
make device-vm-up name=camera site=factory env=prod workload=vision
```

`site=` and any extra `key=value` pairs are stored as device labels for later approval. If you want actual Proxmox VM tags, use `tags=video,west` or `VM_TAGS=video,west`.

Each named device uses its own Terraform workspace, so you can create and remove them independently.

Remove that device VM later with:

```bash
make device-vm-down
```

Or remove one named device:

```bash
make device-vm-down name=database
```

### Approve enrollment

```bash
make approve-enrollment
```

To approve a named device with the labels you saved during `make device-vm-up`, run:

```bash
make approve-enrollment name=database
```

You can also override or add labels at approval time:

```bash
make approve-enrollment name=database site=branch-west fleet=lab-a
```

If you want the command to wait until a pending request exists:

```bash
WAIT_FOR_PENDING=true make approve-enrollment
```

### Create or update the demo fleet

```bash
make fleet-apply
```

### Run the Labs 3 to 5 flow in one command

```bash
make device-demo
```

This runs:

- `make bootc-build`
- `make device-vm-up`
- `make approve-enrollment`
- `make fleet-apply`

`make device-demo` is the early-binding convenience path. If you want the late-binding device flow, run `make bootc-build-latebinding` first and then create the device with `make device-vm-up`.

## Application workflow helpers

Use these after the device is online and already selected by `Fleet/demo`.

### Build the demo application images

```bash
make app-build
```

This builds and pushes:

- the runtime image the device actually runs
- the quadlet package image referenced by Edge Manager

The source of truth for this flow lives under:

```text
applications/hello-web/
```

### Deploy the application through Edge Manager

```bash
make app-deploy
```

This updates the demo fleet and waits for the application to report `Running` on the target device.

### Run the full Lab 6 application flow

```bash
make app-demo
```

This runs:

- `make app-build`
- `make app-deploy`

## Files you will edit most often

- `automation/terraform/environments/demo/terraform.tfvars`
- `automation/terraform/environments/demo/.env`
- `automation/terraform/environments/manual-demo/terraform.tfvars`
- `automation/terraform/environments/manual-demo/.env`
- `automation/ansible/group_vars/all.yml`

## Notes

- `make up` bootstraps a repo-local Ansible virtual environment in `automation/.venv`, so you do not need a separate global Ansible install.
- The demo Terraform environments treat the configured VM IDs as automation-owned. Pick free VM IDs before you apply.
- If `registry_redhat_io_username` and `registry_redhat_io_password` are left blank, the automation reuses `rhsm_username` and `rhsm_password` for `registry.redhat.io`.
- `rhem_auth_provider: keycloak` is the default. Set `rhem_auth_provider: aap` if you want Edge Manager to use Ansible Automation Platform authentication instead.
- Run `make help` from the repo root to see the supported targets.
