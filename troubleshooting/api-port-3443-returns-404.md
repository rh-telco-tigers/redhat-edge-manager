# Browser Shows `404 Page Not Found` On `https://<host>:3443/`

## What it means

Port `3443` is the Edge Manager API endpoint used by the `flightctl` CLI. It is not the normal browser UI endpoint.

## How to fix it manually

Use:

- Browser UI: `https://<host>/`
- CLI or API: `https://<host>:3443`

Example:

```bash
flightctl login "https://edge-manager.example.com:3443"
```
