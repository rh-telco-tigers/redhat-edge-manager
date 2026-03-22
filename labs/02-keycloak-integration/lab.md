# Keycloak integration

**Goal:** run a lightweight Keycloak on a separate RHEL VM, create a dedicated realm and users for Edge Manager, and switch RHEM from the built-in PAM issuer to Keycloak.

## Step 1 — Prepare a separate RHEL VM for Keycloak

Use a second RHEL 9 VM for Keycloak so the identity provider stays separate from the RHEM host.

If you are using the repo’s manual-demo Terraform path, this VM is created by `make rhel-vms-up`. Use the hostnames, IPs, and VM sizes from `automation/terraform/environments/manual-demo/terraform.tfvars`.

Suggested sizing:

- Hostname: `keycloak.rhem-eap.lan`
- Size: `2 vCPU / 4 GB RAM / 40 GB disk`
- Network: same network as the RHEM VM

Make sure the RHEM host can resolve and reach this VM by name before you continue.

## Step 2 — Install Podman on the Keycloak VM

```bash
sudo subscription-manager status

# Register first if needed:
sudo subscription-manager register --username YOUR_RHSM_USER --password YOUR_RHSM_PASSWORD
sudo subscription-manager attach --auto
sudo subscription-manager refresh

sudo dnf install -y podman curl
podman --version
```

## Step 3 — Start Keycloak in Podman

Set the Keycloak admin credentials and container image:

```bash
export KEYCLOAK_ADMIN=admin
export KEYCLOAK_ADMIN_PASSWORD='CHANGEME-keycloak-admin-password'
export KEYCLOAK_IMAGE='quay.io/keycloak/keycloak:26.0.7'
```

Create the import directory:

```bash
sudo mkdir -p /opt/keycloak/import
sudo chown root:root /opt/keycloak/import
```

Start Keycloak:

```bash
sudo podman run -d \
  --name keycloak \
  --replace \
  -p 8080:8080 \
  -e KC_BOOTSTRAP_ADMIN_USERNAME="$KEYCLOAK_ADMIN" \
  -e KC_BOOTSTRAP_ADMIN_PASSWORD="$KEYCLOAK_ADMIN_PASSWORD" \
  -v /opt/keycloak/import:/opt/keycloak/data/import:Z \
  "$KEYCLOAK_IMAGE" \
  start-dev --hostname=http://keycloak.rhem-eap.lan:8080
```

Verify:

```bash
sudo podman ps
curl -s http://keycloak.rhem-eap.lan:8080/ | head
```

This `start-dev` mode is fine for a lab or demo. It is not a production deployment.

## Step 4 — Create the Edge Manager realm, client, and users

Create a new realm named `edge-manager`.

Create a confidential client:

- Client ID: `flightctl-client`
- Client authentication: enabled
- Standard flow: enabled
- Direct access grants: enabled

Set a client secret and save it. You will need the same value on the RHEM host.

Add these redirect URIs:

- `https://rhem.rhem-eap.lan/*`
- `http://localhost:8080/*`

Create a realm role:

- `flightctl-admin`

Create at least these users:

- `edgemanager-admin`
- `edgemanager-ops`

For each user:

1. Set a password.
2. Mark it non-temporary.
3. Add the `flightctl-admin` realm role.

## Step 5 — Update RHEM to use Keycloak

On the RHEM host, back up the current config:

```bash
sudo cp /etc/flightctl/service-config.yaml /etc/flightctl/service-config.yaml.pre-keycloak
```

Edit `/etc/flightctl/service-config.yaml` and replace the auth section so it uses your Keycloak realm.

Use these values:

- issuer: `http://keycloak.rhem-eap.lan:8080/realms/edge-manager`
- client ID: `flightctl-client`
- client secret: the secret from the Keycloak client
- role claim path: `realm_access.roles`

Make sure `pamOidcIssuer.enabled` is set to `false`.

Then restart RHEM:

```bash
sudo systemctl restart flightctl.target
```

## Step 6 — Verify browser and CLI login

Open the RHEM UI:

```text
https://rhem.rhem-eap.lan/
```

Sign in with the Keycloak user you created, for example `edgemanager-admin`.

Then test the CLI:

```bash
export RHEM_API_URL="https://rhem.rhem-eap.lan:3443"
flightctl login "$RHEM_API_URL" -k --username edgemanager-admin --password 'CHANGEME-admin-password'
flightctl whoami
```

If login works but the user is not authorized, check two things in Keycloak:

- the user has the `flightctl-admin` realm role
- the OIDC client exposes that realm role at `realm_access.roles` in the claims Edge Manager reads, not just in the access token
