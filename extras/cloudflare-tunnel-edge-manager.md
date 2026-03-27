# Publish Edge Manager Through Cloudflare Tunnel

Use this for public admin access to Red Hat Edge Manager without opening inbound ports on your network.

This note covers:

- browser UI
- built-in browser login
- optional `flightctl` API access

It does not cover device enrollment on `:7443`.

## Working Layout

Use these public hostnames:

- UI: `rhem.example.com`
- built-in PAM OIDC issuer: `auth.example.com`
- optional API/CLI: `api.rhem.example.com`

Working demo example:

- `rhem.goglides.dev` -> `https://127.0.0.1:443`
- `auth.goglides.dev` -> `https://127.0.0.1:8444`
- `api-rhem.goglides.dev` -> `https://127.0.0.1:3443`

Do not use a path-based route such as `^/api/v1/auth` for the built-in login flow. A dedicated auth hostname is simpler and more reliable.

## 1. Create The Tunnel

In Cloudflare Zero Trust:

1. Go to `Networks` -> `Tunnels`
2. Create a new `Cloudflared` tunnel
3. Copy the connector token

If you run `cloudflared` in Podman on the Edge Manager host, this pattern works:

```bash
export CLOUDFLARE_TUNNEL_TOKEN='YOUR_TUNNEL_TOKEN'

sudo podman run -d \
  --name cloudflared \
  --restart unless-stopped \
  --network host \
  -v /etc/flightctl/pki/ca.crt:/etc/ssl/certs/flightctl-ca.crt:ro \
  cloudflare/cloudflared:latest \
  tunnel --no-autoupdate run --token "${CLOUDFLARE_TUNNEL_TOKEN}"
```

Why:

- `--network host` makes `127.0.0.1` point to the Edge Manager host
- the CA mount lets `cloudflared` trust the built-in Edge Manager CA

## 2. Add The Tunnel Routes

Add these routes in the Cloudflare dashboard.

| Public hostname | Service URL | Origin Server Name | CA Pool |
| --- | --- | --- | --- |
| `rhem.example.com` | `https://127.0.0.1:443` | `rhem.example.com` | `/etc/ssl/certs/flightctl-ca.crt` |
| `auth.example.com` | `https://127.0.0.1:8444` | `rhem.example.com` | `/etc/ssl/certs/flightctl-ca.crt` |
| `api.rhem.example.com` | `https://127.0.0.1:3443` | `api.rhem.example.com` | `/etc/ssl/certs/flightctl-ca.crt` |

Notes:

- the `api` route is optional if you only need browser access
- if `cloudflared` runs directly on the host instead of in Podman, use `/etc/flightctl/pki/ca.crt` as the CA pool path
- for the built-in login flow, use a first-level auth hostname such as `auth.example.com`

## 3. Update Edge Manager

Edit:

```bash
sudoedit /etc/flightctl/service-config.yaml
```

Set the public base domain:

```yaml
global:
  baseDomain: rhem.goglides.dev
```

If you use the built-in PAM OIDC issuer for browser login, set its public issuer URL explicitly:

```yaml
auth:
  type: oidc
  pamOidcIssuer:
    enabled: true
    issuer: https://auth.goglides.dev/api/v1/auth
```

Notes:

- `baseDomain` must be a hostname only
- do not include `https://`, `http://`, or a trailing slash
- `pamOidcIssuer.issuer` must include `/api/v1/auth`
- for the built-in PAM issuer flow, leave `oidc.issuer` and `externalOidcAuthority` empty unless you are using an external IdP

## 4. Rotate Certificates

After changing `baseDomain`, rotate the built-in certificates so the local origin certs match the new DNS name.

Use:

- [changing-edge-manager-base-domain.md](changing-edge-manager-base-domain.md)

## 5. Verify

From your workstation:

```bash
curl -I https://rhem.example.com/
curl https://auth.example.com/api/v1/auth/.well-known/openid-configuration
curl -I https://api.rhem.example.com/
```

If you exposed the API route, test CLI login too:

```bash
flightctl login https://api.rhem.example.com \
  --username YOUR_USERNAME \
  --password 'YOUR_PASSWORD'
```

## Common Problems

`502 Bad Gateway`

- `cloudflared` cannot reach or trust the origin
- verify `--network host`, `Origin Server Name`, and `CA Pool`

`/login` loads but sign-in fails

- the UI route is working, but the built-in OIDC issuer is not
- verify `auth.example.com -> https://127.0.0.1:8444`
- verify `pamOidcIssuer.issuer` matches the public auth hostname

macOS resolves the hostname inconsistently

- flush the local resolver cache:

```bash
sudo dscacheutil -flushcache
sudo killall -HUP mDNSResponder
```

## External IdPs

If you use external Keycloak or AAP instead of the built-in PAM issuer, expose that IdP on a public hostname too and update its redirect URIs and external URL settings.

## References

- [Create a Cloudflare Tunnel](https://developers.cloudflare.com/learning-paths/zero-trust-web-access/connect-private-applications/create-tunnel/)
- [Cloudflare origin parameters](https://developers.cloudflare.com/tunnel/advanced/origin-parameters/)
- [Cloudflare Tunnel troubleshooting](https://developers.cloudflare.com/tunnel/troubleshooting/)
