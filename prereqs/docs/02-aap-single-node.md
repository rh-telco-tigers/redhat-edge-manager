# Step 2 — Ansible Automation Platform (single node)

Based on Red Hat: [Installing AAP components on a single machine](https://docs.redhat.com/en/documentation/red_hat_ansible_automation_platform/2.0-ea/html/red_hat_ansible_automation_platform_installation_guide/single-machine-scenario) (automation controller + DB on same node).

## Prereqs on the VM

- RHEL + valid **AAP subscription** (attach pools per Red Hat).
- **FQDN or IP** resolvable for controller (installer uses nginx).
- Time sync (`chronyd`).

## What the Ansible playbook does

1. Installs base packages (`tar`, `unzip`, …).
2. Copies your **local** AAP setup bundle tarball to the VM.
3. Renders `inventory` from a template (controller + local PostgreSQL).
4. Runs `./setup.sh` (long; use `screen`/`tmux` or Ansible `async`).

## You still must do manually (Red Hat)

1. Download **Ansible Automation Platform setup bundle** from [Red Hat Customer Portal](https://access.redhat.com/) (version matching your subscription).
2. On the VM: `subscription-manager attach` / enable repos per installation guide.

## Commands

```bash
cd prereqs/ansible
cp inventory/hosts.yml.example inventory/hosts.yml
cp group_vars/all.yml.example group_vars/all.yml
# Edit hosts.yml (ansible_host), all.yml (passwords, bundle path)

ansible-playbook -i inventory/hosts.yml playbooks/aap_install.yml
```

## Verify (from Red Hat doc)

Browse `https://<VM_IP>/` — automation controller UI; login with `admin_password` from inventory.

## Important

**Automation Hub** cannot sit on the **same** node as automation controller per Red Hat. This lab targets **controller-only** single-machine scenario. Add a **second VM** later if you need Hub on AAP.
