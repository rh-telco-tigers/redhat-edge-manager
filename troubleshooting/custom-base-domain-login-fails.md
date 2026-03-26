# Login Fails After Changing The Edge Manager Base Domain

Example symptoms:

- the login page shows `Failed to initiate login`
- API logs show OIDC discovery or token validation failures
- the browser can load `https://<new-fqdn>/`, but login still fails

## What it means

After you change `global.baseDomain`, Edge Manager starts using that new FQDN in its built-in URLs, certificates, and OIDC issuer endpoints.

That FQDN must resolve everywhere it is used:

- from the workstation where you open the browser
- from the Edge Manager host itself
- from the Edge Manager containers or services that call the issuer and API internally

If the new FQDN does not resolve consistently, login can fail even when the UI page itself loads.

## Common signs

On the Edge Manager host, these services are the most useful places to look:

- `flightctl-api.service`
- `flightctl-ui.service`
- `flightctl-pam-issuer.service`

Typical checks:

```bash
sudo journalctl -u flightctl-api.service -u flightctl-ui.service -u flightctl-pam-issuer.service -n 200 --no-pager
```

Look for messages such as:

- `lookup <fqdn> ... no such host`
- OIDC discovery failures
- token validation failures

## How to confirm

1. Confirm the configured base domain is only a hostname, not a URL.

The value in `/etc/flightctl/service-config.yaml` should look like:

```yaml
global:
  baseDomain: rhem.example.com
```

Not:

```yaml
global:
  baseDomain: https://rhem.example.com/
```

2. Confirm the FQDN resolves from the Edge Manager host:

```bash
getent hosts rhem.example.com
```

3. Confirm the FQDN resolves from the key Edge Manager containers:

```bash
sudo podman exec flightctl-api getent hosts rhem.example.com
sudo podman exec flightctl-ui getent hosts rhem.example.com
sudo podman exec flightctl-pam-issuer getent hosts rhem.example.com
```

4. Confirm the OIDC discovery document is reachable:

```bash
curl -sk https://rhem.example.com:8444/api/v1/auth/.well-known/openid-configuration
```

## How to fix it manually

The clean fix is proper DNS.

Make sure your chosen Edge Manager FQDN has working forward resolution in the DNS environment used by:

- your workstation
- the Edge Manager host
- the local container networking on that host

If you are doing a small lab without full DNS infrastructure, make sure the host and clients have consistent host resolution for the same FQDN, then verify the Edge Manager services can resolve it locally before retrying login.

If you also rotated certificates after the base-domain change, make sure the current CA is trusted on the workstation. See [`extras/trusting-lab-certificates.md`](../extras/trusting-lab-certificates.md).

If you changed `baseDomain`, review the full base-domain change flow in [`extras/changing-edge-manager-base-domain.md`](../extras/changing-edge-manager-base-domain.md).
