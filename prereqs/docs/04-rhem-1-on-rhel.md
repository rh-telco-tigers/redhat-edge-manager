# Red Hat Edge Manager 1.0 on RHEL

Official collection: [Red Hat Edge Manager 1.0](https://docs.redhat.com/en/documentation/red_hat_edge_manager/1.0/) → [Installing on RHEL](https://docs.redhat.com/en/documentation/red_hat_edge_manager/1.0/html/installing_red_hat_edge_manager_on_red_hat_enterprise_linux/).

**Important:** Terraform defaults to a **RHEL 9 KVM guest image** on Proxmox. Upload the qcow2 first — [rhel-guest-image-proxmox.md](rhel-guest-image-proxmox.md).

## Prerequisites (from product doc)

- RHEL minimal install, **4 cores / 16 GB RAM** recommended, root/sudo + SSH  
- **Podman** (for `registry.redhat.io` login and PAM issuer container)  
- **DNS name** resolving to the RHEM host (or use IP + TLS caveats for lab)  
- **Active Edge Manager subscription** — enable repo (example for RHEL 9 x86_64):

```bash
sudo subscription-manager repos --enable edge-manager-1.0-for-rhel-9-x86_64-rpms
```

## Steps (concise)

1. **Registry**

```bash
sudo podman login registry.redhat.io
```

2. **Install services**

```bash
sudo dnf install -y flightctl-services
sudo systemctl enable --now flightctl.target
sudo systemctl list-units 'flightctl-*.service'
```

3. **PAM / local users** (default OIDC via PAM issuer)

Per doc: create `flightctl-admin` group and an admin user **inside** the `flightctl-pam-issuer` container, then `usermod -aG flightctl-admin`.

4. **CLI**

```bash
sudo dnf install -y flightctl-cli
flightctl version
flightctl login https://<RHEM_HOST>:3443 --username <USER> --password <PASS>
```

5. **UI** — `https://<RHEM_HOST>:3443/` (TLS / self-signed: follow browser + CLI prompts).

## Next (doc)

[Operating system images for Red Hat Edge Manager](https://docs.redhat.com/en/documentation/red_hat_edge_manager/1.0/) (same doc set).
