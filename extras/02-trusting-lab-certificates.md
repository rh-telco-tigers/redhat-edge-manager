# Trust the Edge Manager certificate on your workstation

Use this when `flightctl login` warns that the server certificate is not trusted and you want your local machine to trust the Edge Manager endpoint instead of using `--insecure-skip-tls-verify`.

This is a workstation task. Run these commands from the machine where you use the browser and the `flightctl` CLI.

## Step 1 — Choose the Edge Manager DNS name

Use the DNS name that users actually browse to.

Examples:

- `rhem.example.com`
- `edge-manager.lab.example.com`

Set it once for the commands below:

```bash
export EDGE_MANAGER_HOST="YOUR_EDGE_MANAGER_FQDN"
```

If you run commands directly on the Edge Manager host, you can use:

```bash
export EDGE_MANAGER_HOST="$(hostname -f)"
```

## Step 2 — Export the correct certificate

If Red Hat Edge Manager is using its built-in certificate generation, trust the issuing CA certificate, not the leaf server certificate.

On the Edge Manager host, the CA is here:

```bash
/etc/flightctl/pki/ca.crt
```

Copy that CA certificate to the workstation where you run the browser and `flightctl`.

Example:

```bash
scp <admin_user>@${EDGE_MANAGER_HOST}:/etc/flightctl/pki/ca.crt flightctl-ca.crt
```

If you are logged into the Edge Manager host itself, you can simply copy it locally:

```bash
cp /etc/flightctl/pki/ca.crt flightctl-ca.crt
```

If you use custom certificates from your own PKI, export and trust the issuing CA for that certificate chain instead.

You can inspect the CA certificate with:

```bash
openssl x509 -in flightctl-ca.crt -noout -subject -issuer -dates
```

For reference, the API server certificate itself is usually at:

```bash
/etc/flightctl/pki/flightctl-api/server.crt
```

You can inspect it with:

```bash
openssl x509 -in /etc/flightctl/pki/flightctl-api/server.crt -noout -subject -issuer -dates -ext subjectAltName
```

Confirm the server certificate contains the DNS name that users actually connect to.

## Step 3 — Trust the certificate on macOS

On macOS, add the certificate to the System keychain and mark it as trusted:

```bash
sudo security add-trusted-cert \
  -d \
  -r trustRoot \
  -k /Library/Keychains/System.keychain \
  flightctl-ca.crt
```

Then flush the local caches:

```bash
sudo dscacheutil -flushcache
sudo killall -HUP mDNSResponder
```

## Step 4 — Trust the certificate on RHEL or Fedora

If your workstation is another RHEL or Fedora system and you already copied `flightctl-ca.crt` there:

```bash
sudo cp flightctl-ca.crt /etc/pki/ca-trust/source/anchors/
sudo update-ca-trust
```

If you are running these commands directly on the Edge Manager host itself, copy from the source path instead:

```bash
sudo cp /etc/flightctl/pki/ca.crt /etc/pki/ca-trust/source/anchors/flightctl-ca.crt
sudo update-ca-trust
```

## Step 5 — Verify the trust path

Confirm the browser and CLI can use the certificate without an insecure override:

```bash
curl -I "https://${EDGE_MANAGER_HOST}/"
flightctl login "https://${EDGE_MANAGER_HOST}:3443" \
  --username YOUR_USERNAME \
  --password 'YOUR_PASSWORD'
```

If you want to verify the trust bundle directly on a RHEL or Fedora system:

```bash
openssl verify -CAfile /etc/pki/tls/certs/ca-bundle.crt /etc/flightctl/pki/flightctl-api/server.crt
```

If `flightctl login` still warns that the certificate is not trusted, remove the old CA certificate, export the current CA again, and reinstall it. This often happens when the Edge Manager host was rebuilt and a new self-signed CA was generated.

## Step 6 — Remove the certificate later if needed

macOS:

```bash
sudo security delete-certificate -c "${EDGE_MANAGER_HOST}" /Library/Keychains/System.keychain
```

RHEL or Fedora:

```bash
sudo rm -f /etc/pki/ca-trust/source/anchors/flightctl-ca.crt
sudo update-ca-trust
```

## Notes

- In a production environment, trust the issuing CA instead of trusting an individual leaf certificate whenever possible.
- The hostname in the certificate must match the DNS name that users access.
- If you use Keycloak, AAP, or Satellite with custom certificates, repeat the same trust process for those endpoints when your workstation needs to talk to them directly.
