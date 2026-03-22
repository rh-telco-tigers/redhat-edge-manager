# Ansible Automation Platform integration

Use this lab when you want Edge Manager to authenticate users through an existing Ansible Automation Platform instance.

Complete [01-edge-manager-installation.md](01-edge-manager-installation.md) first. If you want to use Keycloak instead, use [02-keycloak-integration.md](02-keycloak-integration.md).

## Step 1 — Set the integration values

```bash
export RHEM_HOST_FQDN="rhem-prereq-rhel-01.rhem-eap.lan"
export RHEM_UI_URL="https://${RHEM_HOST_FQDN}"
export RHEM_API_URL="https://${RHEM_HOST_FQDN}:3443"
export AAP_URL="https://aap.rhem-eap.lan"
```

Use the Edge Manager certificate hostname for `RHEM_HOST_FQDN`.

## Step 2 — Choose the OAuth setup method in AAP

You can use either of these methods:

- Automatic setup: create a write-scoped OAuth token in AAP and let Edge Manager create the OAuth application for you.
- Manual setup: create the OAuth application yourself in AAP and copy its client ID into the Edge Manager configuration.

### Option A — Automatic setup

In the AAP web console:

1. Go to **Access Management** → **Users**.
2. Open a user that has write access to the `Default` organization. For the first test, use an AAP administrator account.
3. Open the **Tokens** tab.
4. Click **Create token**.
5. Set **Scope** to `Write`.
6. Copy the token value.

Keep that token for the next step.

### Option B — Manual setup

In the AAP web console:

1. Go to **Access Management** → **OAuth Applications**.
2. Click **Create OAuth application**.
3. Use values like these:

- Name: `Red Hat Edge Manager`
- URL: `https://rhem-prereq-rhel-01.rhem-eap.lan`
- Organization: `Default`
- Authorization grant type: `Authorization code`
- Client: `Public`
- Redirect URIs: `https://rhem-prereq-rhel-01.rhem-eap.lan:443/callback http://127.0.0.1/callback`

Save the application and copy the **Client ID**.

## Step 3 — Update the Edge Manager service configuration

Back up the current configuration on the Edge Manager host:

```bash
sudo cp /etc/flightctl/service-config.yaml /etc/flightctl/service-config.yaml.pre-aap
```

Edit `/etc/flightctl/service-config.yaml`.

If you are using the automatic setup method, leave `oAuthApplicationClientId` empty and set `oAuthToken`:

```yaml
global:
  baseDomain: rhem-prereq-rhel-01.rhem-eap.lan
  auth:
    type: aap
    insecureSkipTlsVerify: false
    aap:
      apiUrl: https://aap.rhem-eap.lan
      externalApiUrl: https://aap.rhem-eap.lan
      oAuthApplicationClientId:
      oAuthToken: CHANGEME_AAP_WRITE_TOKEN
    oidc:
      enabled: false
    pamOidcIssuer:
      enabled: false
```

If you are using the manual setup method, set `oAuthApplicationClientId` and leave `oAuthToken` empty:

```yaml
global:
  baseDomain: rhem-prereq-rhel-01.rhem-eap.lan
  auth:
    type: aap
    insecureSkipTlsVerify: false
    aap:
      apiUrl: https://aap.rhem-eap.lan
      externalApiUrl: https://aap.rhem-eap.lan
      oAuthApplicationClientId: CHANGEME_AAP_CLIENT_ID
      oAuthToken:
    oidc:
      enabled: false
    pamOidcIssuer:
      enabled: false
```

If your AAP instance uses a self-signed certificate and you are not installing its CA into `/etc/flightctl/pki/auth/ca.crt`, set `insecureSkipTlsVerify: true` for the lab.

Restart Edge Manager:

```bash
sudo systemctl restart flightctl.target
```

## Step 4 — Verify browser login

Open the Edge Manager web console:

```text
https://rhem-prereq-rhel-01.rhem-eap.lan/
```

You should be redirected to AAP for login.

Sign in with an AAP user that can access the `Default` organization.

## Step 5 — Verify CLI login

If you used the manual setup method, run:

```bash
flightctl login "${RHEM_API_URL}" \
  --web \
  --client-id CHANGEME_AAP_CLIENT_ID \
  --insecure-skip-tls-verify
```

If you used the automatic setup method, Edge Manager creates the OAuth application during startup. Read the generated client ID from the service configuration and then use it for the CLI login:

```bash
grep oAuthApplicationClientId /etc/flightctl/service-config.yaml
```

Then run:

```bash
flightctl login "${RHEM_API_URL}" \
  --web \
  --client-id CHANGEME_GENERATED_AAP_CLIENT_ID \
  --insecure-skip-tls-verify
```

## Step 6 — Optional: verify non-interactive login with the token

If you created a write-scoped token, you can also use it directly:

```bash
flightctl login "${RHEM_API_URL}" \
  --token CHANGEME_AAP_WRITE_TOKEN \
  --insecure-skip-tls-verify
```

This is the same non-interactive login model used by the automation in this repo when AAP authentication is selected.
