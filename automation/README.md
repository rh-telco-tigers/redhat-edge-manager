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
- optionally install AAP when `aap_install_enabled: true`

`make down` destroys the Terraform-managed demo VMs.

`make create-rhel9` provisions one standalone RHEL 9 VM using role-based defaults.

`make up` bootstraps a repo-local Ansible environment in `automation/.venv` automatically, so you do not need a separate global `ansible-playbook` install on your Mac.

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
