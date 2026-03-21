# Keycloak integration

**Goal:** run a lightweight Keycloak on a separate RHEL VM, create a dedicated realm and users for Edge Manager, and switch RHEM from the built-in PAM issuer to Keycloak.

**Files in this folder:**
- `lab.md` — step-by-step process
- `realm-edge-manager.json.template` — Keycloak realm, client, and default users
- `service-config.keycloak.yaml.example` — `service-config.yaml` example for external OIDC

## Step 1 — Create a separate Keycloak VM

Use the same RHEL guest image / qcow2 workflow you already used for the RHEM VM. Create a second VM dedicated to Keycloak.

Suggested settings:
- VM name: `rhem-keycloak-01`
- Hostname / DNS: `keycloak.rhem-eap.lan`
- Size: `2 vCPU / 4 GB RAM / 40 GB disk`
- Network: same network as the RHEM VM

Keep the Keycloak VM separate from the RHEM VM. Reuse the same Proxmox/Terraform process from [`../01-edge-manager-installation/lab.md`](../01-edge-manager-installation/lab.md), but pick a new VM ID, hostname, and IP or DHCP lease.

## Step 2 — Register the Keycloak VM and install Podman

Run these commands on the new Keycloak VM:

```bash
sudo subscription-manager status

# If the host is not registered yet:
sudo subscription-manager register --username YOUR_RHSM_USER --password YOUR_RHSM_PASSWORD
# Or use an activation key instead:
# sudo subscription-manager register --org=YOUR_ORG --activationkey=YOUR_KEY

sudo subscription-manager attach --auto
sudo subscription-manager refresh
sudo dnf install -y podman
podman --version
```

## Step 3 — Prepare the Keycloak realm file

In this folder, copy the template and replace the `CHANGEME` values before moving it to the Keycloak VM:

```bash
cp realm-edge-manager.json.template realm-edge-manager.json
```

Update at least these values in `realm-edge-manager.json`:
- Keycloak hostname used in redirect URIs
- RHEM hostname used in redirect URIs
- client secret for `flightctl-client`
- passwords for the default users

## Step 4 — Start Keycloak in Podman

Copy the edited realm file to the Keycloak VM and start Keycloak in a lightweight container.

```bash
sudo mkdir -p /opt/keycloak/import
sudo cp realm-edge-manager.json /opt/keycloak/import/realm-edge-manager.json

sudo podman run -d \
  --name keycloak \
  --restart=unless-stopped \
  -p 8080:8080 \
  -e KC_BOOTSTRAP_ADMIN_USERNAME=admin \
  -e KC_BOOTSTRAP_ADMIN_PASSWORD='CHANGEME-keycloak-admin-password' \
  -v /opt/keycloak/import:/opt/keycloak/data/import:Z \
  quay.io/keycloak/keycloak:26.0.7 \
  start-dev --import-realm --hostname=http://keycloak.rhem-eap.lan:8080
```

Check that Keycloak is up:

```bash
sudo podman ps
curl -s http://keycloak.rhem-eap.lan:8080/realms/edge-manager/.well-known/openid-configuration | head
```

This uses `start-dev` for a lightweight lab setup. It is acceptable for demos and testing, not for production.

## Step 5 — Point RHEM to Keycloak instead of the built-in PAM issuer

On the RHEM VM:

```bash
sudo cp /etc/flightctl/service-config.yaml /etc/flightctl/service-config.yaml.bak
sudoedit /etc/flightctl/service-config.yaml
```

Use [`service-config.keycloak.yaml.example`](./service-config.keycloak.yaml.example) as the reference for the `global.auth` block. The important changes are:
- keep `type: oidc`
- set `pamOidcIssuer.enabled: false`
- set `oidc.issuer` to the Keycloak realm issuer URL
- set `oidc.clientId` and `oidc.clientSecret` to the Keycloak client values
- use `claimPath: [realm_access, roles]` for roles
- keep organization assignment static with `default`

After editing the file, restart Flight Control:

```bash
sudo systemctl restart flightctl.target
sudo systemctl status flightctl-api flightctl-ui --no-pager
```

## Step 6 — Verify browser and CLI login

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
