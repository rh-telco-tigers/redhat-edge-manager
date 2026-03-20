# Red Hat Edge Manager 1.0 on RHEL

Official collection: [Red Hat Edge Manager 1.0](https://docs.redhat.com/en/documentation/red_hat_edge_manager/1.0/) → [Installing on RHEL](https://docs.redhat.com/en/documentation/red_hat_edge_manager/1.0/html/installing_red_hat_edge_manager_on_red_hat_enterprise_linux/).

**Important:** Terraform defaults to a **RHEL 9 KVM guest image** on Proxmox. Upload the qcow2 first — [rhel-guest-image-proxmox.md](rhel-guest-image-proxmox.md).

## Prerequisites (from product doc)

- RHEL minimal install, **4 cores / 16 GB RAM** recommended, root/sudo + SSH  
- **Podman** (for `registry.redhat.io` login and PAM issuer container)  
- **DNS name** resolving to the RHEM host (or use IP + TLS caveats for lab)  
- **RHEL registered with a subscription that includes this system** — the KVM guest image does **not** auto-register. If you run `repos --enable` first and see *“This system has no repositories available through subscriptions”*, the host has **no entitled repos** yet (unregistered, no pool attached, or wrong account).

### Register and attach (before enabling Edge Manager repo)

```bash
sudo subscription-manager status
# If "Overall Status: Unknown" or not registered:
sudo subscription-manager register --username YOUR_RHSM_USER --password YOUR_PASSWORD
# Or activation key (typical for automation):
# sudo subscription-manager register --org=YOUR_ORG --activationkey=YOUR_KEY

sudo subscription-manager attach --auto
# Or attach a specific pool: subscription-manager list --available --matches 'Red Hat Enterprise Linux'
# then: sudo subscription-manager attach --pool=POOL_ID

sudo subscription-manager refresh
sudo subscription-manager repos --list-enabled
```

When **base** RHEL repos show up, enable Edge Manager:

```bash
sudo subscription-manager repos --enable edge-manager-1.0-for-rhel-9-x86_64-rpms
```

You also need an entitlement that includes **Red Hat Edge Manager** (not only RHEL) — if the repo still does not appear after a good `attach`, confirm the SKU/subscription with your account team or [Red Hat Customer Portal](https://access.redhat.com/).

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
