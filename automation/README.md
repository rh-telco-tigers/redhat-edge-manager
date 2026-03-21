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

## First run

1. Create the local files:

```bash
make init-files
```

2. Edit:

- `automation/terraform/environments/demo/terraform.tfvars`
- `automation/ansible/group_vars/all.yml`

3. Run:

```bash
make up
```

4. Tear down:

```bash
make down
```

## Single VM helper

Examples:

```bash
make create-rhel9 ROLE=keycloak VM_ID=121 IPV4_CIDR=192.168.4.121/22
make create-rhel9 ROLE=edge-manager VM_ID=122 IPV4_CIDR=192.168.4.122/22 VM_NAME=rhem-lab-02 DNS_NAME=rhem02
```

Accepted `ROLE` presets:

- `edge-manager`
- `keycloak`
- `dns`
- `aap`
- `generic`

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
