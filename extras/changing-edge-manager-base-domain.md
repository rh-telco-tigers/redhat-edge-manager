# Change the Edge Manager base domain and rotate built-in certificates

Use this when you want Edge Manager to present a different external DNS name, for example `rhem.rhem-eap.lan`, instead of the current host FQDN.

The setting lives in:

```bash
/etc/flightctl/service-config.yaml
```

This note applies to deployments that use the built-in certificate generation in:

```yaml
global:
  generateCertificates: builtin
```

## What `baseDomain` means

`global.baseDomain` is the hostname or FQDN that Edge Manager uses to derive its external service URLs and certificate SANs.

Do not include:

- `https://`
- `http://`
- a trailing slash

Correct:

```yaml
global:
  baseDomain: rhem.rhem-eap.lan
```

Not correct:

```yaml
global:
  baseDomain: https://rhem.rhem-eap.lan/
```

With `baseDomain: rhem.rhem-eap.lan`, Edge Manager derives values such as:

- UI: `https://rhem.rhem-eap.lan/`
- API: `https://rhem.rhem-eap.lan:3443/`
- agent endpoint: `https://rhem.rhem-eap.lan:7443/`

## Important behavior

If `global.baseDomain` is empty, Edge Manager defaults to `hostname -f`.

If you later change `global.baseDomain`, the existing built-in certificates are not automatically replaced just because the config changed. The built-in generator skips existing certificate files.

That means a hostname change normally requires a certificate regeneration step.

## `flightctl certificate request` is not the server cert rotation command

`flightctl certificate request` is for device enrollment certificates.

It does not rotate the Edge Manager server certificates in `/etc/flightctl/pki/`.

You can confirm that with:

```bash
flightctl certificate --help
```

The built-in server certificates are created by:

```bash
sudo systemctl cat flightctl-certs-init.service
```

That service runs:

```bash
/usr/share/flightctl/init_certs.sh
```

## Step 1 — Set the new base domain

Edit the Edge Manager config:

```bash
sudoedit /etc/flightctl/service-config.yaml
```

Set:

```yaml
global:
  baseDomain: rhem.rhem-eap.lan
```

Leave `generateCertificates: builtin` in place if you want Edge Manager to keep generating its own certificates.

If `sudoedit` is not available, use the editor that exists on the host. Minimal RHEL images often do not include `vim`.

## Step 2 — Use the safe rotation path

If your goal is to move Edge Manager to a new DNS name, the safe path is to keep the existing CA and rotate only the service leaf certificates.

This updates the hostname SANs without deleting signer material or other PKI content that the services still need.

## Step 3 — Rotate only the service certificates

Stop the stack and back up the existing PKI:

```bash
sudo systemctl stop flightctl.target flightctl-certs-init.service
sudo cp -a /etc/flightctl/pki /etc/flightctl/pki.backup.$(date +%Y%m%d%H%M%S)
```

Remove only the service leaf certificates and keys:

```bash
sudo rm -f /etc/flightctl/pki/flightctl-api/server.crt
sudo rm -f /etc/flightctl/pki/flightctl-api/server.key
sudo rm -f /etc/flightctl/pki/flightctl-ui/server.crt
sudo rm -f /etc/flightctl/pki/flightctl-ui/server.key
sudo rm -f /etc/flightctl/pki/flightctl-pam-issuer/server.crt
sudo rm -f /etc/flightctl/pki/flightctl-pam-issuer/server.key
sudo rm -f /etc/flightctl/pki/flightctl-alertmanager-proxy/server.crt
sudo rm -f /etc/flightctl/pki/flightctl-alertmanager-proxy/server.key
sudo rm -f /etc/flightctl/pki/flightctl-cli-artifacts/server.crt
sudo rm -f /etc/flightctl/pki/flightctl-cli-artifacts/server.key
sudo rm -f /etc/flightctl/pki/flightctl-telemetry-gateway/server.crt
sudo rm -f /etc/flightctl/pki/flightctl-telemetry-gateway/server.key
```

Start the stack again:

```bash
sudo systemctl start flightctl-certs-init.service
sudo systemctl start flightctl.target
```

## Step 4 — Verify the new certificate SANs

Inspect the API certificate:

```bash
sudo openssl x509 \
  -in /etc/flightctl/pki/flightctl-api/server.crt \
  -noout -subject -issuer -dates -ext subjectAltName
```

Confirm the new DNS name appears in `subjectAltName`.

If you changed `baseDomain` to `rhem.rhem-eap.lan`, you should expect SANs such as:

- `DNS:rhem.rhem-eap.lan`
- `DNS:api.rhem.rhem-eap.lan`
- `DNS:agent-api.rhem.rhem-eap.lan`

## Step 5 — Verify the live endpoints

From the Edge Manager host:

```bash
export RHEM_HOST="rhem.rhem-eap.lan"
curl -I "https://${RHEM_HOST}/"
curl -I "https://${RHEM_HOST}:3443/"
```

If DNS is not available yet on that machine, use the host file or your DNS service first. The certificate can only validate cleanly when the hostname you use matches the certificate SANs.

## Step 6 — Re-trust the CA on workstations if needed

If you rotated the built-in CA, every workstation that talks to Edge Manager must trust the new CA.

Use:

- [trusting-lab-certificates.md](trusting-lab-certificates.md)

## Notes

- Changing `baseDomain` affects more than the browser URL. It also affects the API, PAM issuer defaults, and other generated service URLs.
- If you use external Keycloak or AAP integration, review redirect URIs and callback URLs after changing `baseDomain`.
- If you use your own custom certificates instead of `generateCertificates: builtin`, do not delete `/etc/flightctl/pki/*`. Install the new certificates that match the new hostname instead.

## Recovery

Use this section only if the normal leaf-certificate rotation path did not solve the problem or the stack is already in a broken state.

### Restore the PKI from backup

If services fail after a certificate change, restore the last backup first:

```bash
sudo systemctl stop flightctl.target flightctl-certs-init.service
sudo rsync -a /etc/flightctl/pki.backup.YYYYMMDDHHMMSS/ /etc/flightctl/pki/
sudo systemctl start flightctl.target
```

After the stack is healthy again, return to the safe leaf-certificate rotation path above.

### Full built-in PKI rotation

Do not use this as the first choice for a hostname change.

A full wipe of `/etc/flightctl/pki/*` is more destructive than it looks. The API and other services also mount content such as:

- `/etc/flightctl/pki/db`
- `/etc/flightctl/pki/flightctl-api/client-signer.crt`
- `/etc/flightctl/pki/flightctl-api/client-signer.key`
- `/etc/flightctl/pki/ca-bundle.crt`

`flightctl-certs-init.service` regenerates the certificate set, but it does not rebuild every non-leaf path under `/etc/flightctl/pki`. A blind `rm -rf /etc/flightctl/pki/*` can leave the stack broken.

If you truly want a new built-in CA as well as new server certificates, treat it as an advanced recovery task:

```bash
sudo systemctl stop flightctl.target flightctl-certs-init.service
sudo cp -a /etc/flightctl/pki /etc/flightctl/pki.backup.$(date +%Y%m%d%H%M%S)
sudo mkdir -p /root/flightctl-pki-recovery
sudo cp -a /etc/flightctl/pki/db /root/flightctl-pki-recovery/db
sudo rm -rf /etc/flightctl/pki/*
sudo cp -a /root/flightctl-pki-recovery/db /etc/flightctl/pki/db
sudo systemctl start flightctl-certs-init.service
sudo systemctl start flightctl.target
```

If you use this path, re-trust the new CA on every workstation that talks to Edge Manager.
