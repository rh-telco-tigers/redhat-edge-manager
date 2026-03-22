# Ansible Automation Platform single-node reference

This is an optional reference for the single-node AAP path used by the automation stack.

If you want the end-user manual integration steps, use [../../labs/02a-aap-integration.md](../../labs/02a-aap-integration.md). That lab covers both the automatic token-based setup and the manual OAuth application setup.

Source of truth:
[Installing AAP components on a single machine](https://docs.redhat.com/en/documentation/red_hat_ansible_automation_platform/)

## What this repo supports

The repo automation supports a controller-only single-machine install:

- automation controller
- local PostgreSQL

It does not try to place Automation Hub on the same node.

## What you still need

- a dedicated RHEL host for AAP
- a valid AAP subscription
- the AAP setup bundle tarball downloaded from Red Hat
- the bundle path set in `automation/ansible/group_vars/all.yml`

## Automation entry point

```bash
cd automation/ansible
ansible-playbook -l aap_controllers playbooks/aap_install.yml
```

Or let the full stack include AAP as part of:

```bash
make up
```

## Verification

Open `https://<aap-host>/` and log in with the credentials rendered into the installer inventory.
