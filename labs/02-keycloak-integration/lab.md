# Keycloak integration

**Goal:** connect Edge Manager to an existing Keycloak instance and use Keycloak for login and authorization.

## Before you start

- Lab 1 is already complete and Edge Manager is working.
- You already have an existing Keycloak instance you can administer.
- You know the Edge Manager browser hostname, the Edge Manager API hostname, and the Keycloak realm URL you want to use.

## Step 1 — Pick the integration values

Use values like these for the lab:

```bash
export RHEM_HOST_FQDN="edge-manager.example.com"
export RHEM_UI_URL="https://${RHEM_HOST_FQDN}"
export RHEM_API_URL="https://${RHEM_HOST_FQDN}:3443"
export KEYCLOAK_URL="https://keycloak.example.com"
export KEYCLOAK_REALM="edge-manager"
export FLIGHTCTL_CLIENT_ID="flightctl-client"
```

Adjust the values if your hostnames are different.

## Step 2 — Create the Keycloak realm, roles, and users

Create a new realm named `edge-manager`.

Create a realm role:

- `flightctl-admin`

Create at least these users:

- `edgemanager-admin`
- `edgemanager-ops`

Set these fields when you create the users so first login does not stop on the profile-update screen:

- First name
- Last name
- Email

Example values are fine for the lab:

- `edgemanager-admin@example.com`
- `edgemanager-ops@example.com`

For each user:

1. Set a password.
2. Mark it non-temporary.
3. Add the `flightctl-admin` realm role.
4. Add the built-in `offline_access` realm role.

Do not create a new `offline_access` role. Keycloak already includes it.

## Step 3 — Create the Edge Manager OIDC client

Create an OpenID Connect client for Edge Manager with these settings:

- Client ID: `flightctl-client`
- Client authentication: disabled
- Access type: public
- Standard flow: enabled
- Direct access grants: enabled
- Service accounts: disabled

Add these redirect URIs:

- `https://edge-manager.example.com/*`
- `https://edge-manager.example.com:443/*`
- `http://localhost:8080/*`

Set web origins to:

- `+`

Make sure the client has:

- default client scopes: `profile`, `email`, `roles`, `web-origins`
- optional client scope: `offline_access`

## Step 4 — Expose realm roles in the claims Edge Manager reads

This is the part that controls authorization inside Edge Manager.

If this is missing, login can succeed but the UI will still show `Restricted Access`.

Add a protocol mapper to the `flightctl-client` client with these values:

- Name: `realm roles in userinfo`
- Mapper type: `User Realm Role`
- Token claim name: `realm_access.roles`
- Claim JSON type: `String`
- Multivalued: enabled
- Add to access token: enabled
- Add to ID token: enabled
- Add to userinfo: enabled

After this change, the Keycloak claims that Edge Manager reads should include:

- `realm_access.roles`

## Step 5 — Update Edge Manager to use Keycloak

On the RHEM host, back up the current config:

```bash
sudo cp /etc/flightctl/service-config.yaml /etc/flightctl/service-config.yaml.pre-keycloak
```

Edit `/etc/flightctl/service-config.yaml` and update the auth section so it uses your Keycloak realm.

Use values like these:

```yaml
global:
  auth:
    type: oidc
    insecureSkipTlsVerify: true
    oidc:
      enabled: true
      issuer: https://keycloak.example.com/realms/edge-manager
      externalOidcAuthority: https://keycloak.example.com/realms/edge-manager
      clientId: flightctl-client
      clientSecret:
      organizationAssignment:
        type: static
        organizationName: default
      usernameClaim:
        - preferred_username
      roleAssignment:
        type: dynamic
        separator: ":"
        claimPath:
          - realm_access
          - roles
    pamOidcIssuer:
      enabled: false
```

If your Keycloak server uses trusted HTTPS, set `insecureSkipTlsVerify: false`.

Then restart RHEM:

```bash
sudo systemctl restart flightctl.target
```

## Step 6 — Verify browser and CLI login

Open the RHEM UI:

```text
https://edge-manager.example.com/
```

Sign in with the Keycloak user you created, for example `edgemanager-admin`.

If you just changed roles or claim mappers, fully log out first and then log back in with a fresh browser session.

Optional: test the CLI from your workstation using the browser-based OIDC flow:

```bash
flightctl login "$RHEM_API_URL" -k
```

If login works but the user is still not authorized inside Edge Manager, check all of these:

- the user has the `flightctl-admin` realm role
- the user has the built-in `offline_access` realm role
- the `flightctl-client` client exposes `realm_access.roles` in `userinfo`, not just in the access token
