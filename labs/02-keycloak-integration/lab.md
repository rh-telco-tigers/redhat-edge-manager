# Keycloak integration

**Goal:** run a lightweight Keycloak on a separate RHEL VM, create a dedicated realm and users for Edge Manager, and switch RHEM from the built-in PAM issuer to Keycloak.

**Files in this folder:**
- `lab.md` — step-by-step process
- `terraform/` — creates the dedicated RHEL Keycloak VM
- `ansible/` — installs Keycloak in Podman and updates RHEM to use external OIDC
- `realm-edge-manager.json.template` — static realm example kept for reference
- `service-config.keycloak.yaml.example` — static `service-config.yaml` example kept for reference

## Step 1 — Create a separate Keycloak VM with Terraform

The `terraform/` folder automates creation of a second RHEL VM dedicated to Keycloak. It uses the same RHEL guest image/qcow2 workflow as the RHEM VM.

Suggested settings:
- VM name: `rhem-keycloak-01`
- Hostname / DNS: `keycloak.rhem-eap.lan`
- Size: `2 vCPU / 4 GB RAM / 40 GB disk`
- Network: same network as the RHEM VM

Use the example files in `terraform/`:

```bash
cd terraform
cp .env.example .env
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars`:
- set a free `vm_id`
- confirm `proxmox_endpoint`, `proxmox_node`, and `disk_storage`
- keep `cloud_image_import_id` pointed at the same RHEL guest image as the RHEM VM, or set `cloud_image_download_url`
- set your SSH public key

Then apply:

```bash
./tf.sh init -input=false
./tf.sh apply -auto-approve -input=false
```

After apply, use `terraform output` to capture the Keycloak VM IP for the Ansible inventory.

## Step 2 — Set Ansible inventory and variables

The `ansible/` folder automates:
- host registration prerequisites needed for the Keycloak VM
- Podman install
- Keycloak container deployment
- realm, client, and default user creation
- RHEM configuration switch from the built-in PAM issuer to external Keycloak OIDC

Prepare the local files:

```bash
cd ../ansible
cp inventory/hosts.yml.example inventory/hosts.yml
cp group_vars/all.yml.example group_vars/all.yml
```

Edit `inventory/hosts.yml`:
- set the Keycloak VM `ansible_host`
- set the RHEM VM `ansible_host`

Edit `group_vars/all.yml`:
- set `keycloak_public_url`
- set `rhem_base_domain`, `rhem_ui_url`, and `rhem_api_url`
- set `flightctl_client_secret`
- set the bootstrap Keycloak admin password
- set the default Edge Manager user passwords

If you do not have DNS for `keycloak.rhem-eap.lan`, use an IP-based `keycloak_public_url` such as `http://192.168.4.36:8080`.

## Step 3 — Run the automation

Run the Ansible playbook from `ansible/`:

```bash
ansible-playbook playbooks/keycloak_integration.yml
```

This playbook:
- installs Podman on the Keycloak VM
- writes the Keycloak realm import from Ansible variables
- starts Keycloak as a systemd-managed Podman container
- backs up `/etc/flightctl/service-config.yaml` on the RHEM VM
- replaces the RHEM auth config to use the Keycloak realm
- restarts `flightctl.target`

## Step 4 — Verify Keycloak

On the Keycloak VM:

```bash
sudo podman ps
curl -s "${KEYCLOAK_PUBLIC_URL:-http://keycloak.rhem-eap.lan:8080}/realms/edge-manager/.well-known/openid-configuration" | head
```

This setup uses `start-dev` for a lightweight lab environment. It is acceptable for demos and testing, not for production.

## Step 5 — Verify browser and CLI login

Default users from the realm template:
- `edgemanager-admin`
- `edgemanager-ops`

Open the RHEM UI:

```text
https://rhem-prereq-rhel-01.rhem-eap.lan/
```

Then test the CLI:

```bash
export RHEM_API_URL="https://rhem-prereq-rhel-01.rhem-eap.lan:3443"
flightctl login "$RHEM_API_URL" -k --username edgemanager-admin --password 'CHANGEME-admin-password'
flightctl whoami
```

If login succeeds but authorization is wrong, check the token role claim. This lab expects Keycloak realm roles to appear at `realm_access.roles`, and the admin user must have the `flightctl-admin` realm role.
