# Keycloak Login Fails With `Invalid Parameter: redirect_uri`

## What it means

The Keycloak client does not allow the exact callback URL that Edge Manager is using.

## How to fix it manually

Add the Edge Manager callback URLs to the Keycloak client.

Typical values:

- `https://edge-manager.example.com/*`
- `https://edge-manager.example.com:443/*`
- `http://localhost:8080/*`

Also confirm the browser URL you are using matches the hostname configured in Edge Manager.
