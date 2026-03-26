# Login Succeeds But The UI Shows `Restricted Access`

## What it means

Authentication worked, but authorization did not. The user signed in, but Edge Manager did not receive the roles or permissions it needs.

## How to fix it manually

If you use Keycloak:

1. Confirm the user has the `flightctl-admin` realm role.
2. Confirm the user also has the built-in `offline_access` role.
3. Confirm the `flightctl-client` client exposes `realm_access.roles` in `userinfo`.
4. Log out fully and start a fresh browser session.

If you use AAP:

1. Confirm the user has the organization access or roles required by your AAP policy.
2. Confirm Edge Manager is pointed at the correct AAP URL.
3. Confirm the OAuth application or token configuration is valid.
4. Log out fully and start a fresh browser session.
