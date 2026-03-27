# Keycloak Login Fails With `invalid_scope`

## What it means

The Keycloak client is missing one or more scopes that Edge Manager requests during login.

## How to fix it manually

Confirm the client allows these scopes:

- `openid`
- `profile`
- `email`
- `roles`
- `offline_access`

If the user can log in but later fails during token exchange, also confirm the user has the built-in `offline_access` role.
