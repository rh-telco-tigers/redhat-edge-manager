# Red Hat Edge Manager 1.0 on RHEL

Official collection: [Red Hat Edge Manager 1.0](https://docs.redhat.com/en/documentation/red_hat_edge_manager/1.0/) → [Installing on RHEL](https://docs.redhat.com/en/documentation/red_hat_edge_manager/1.0/html/installing_red_hat_edge_manager_on_red_hat_enterprise_linux/).

**Important:** Terraform defaults to a **RHEL 9 KVM guest image** on Proxmox. Upload the qcow2 first — [rhel-guest-image-proxmox.md](rhel-guest-image-proxmox.md).

## Prerequisites (from product doc)

- RHEL minimal install, **4 cores / 16 GB RAM** recommended, root/sudo + SSH  
- **Podman** (install it explicitly on the minimal cloud image before `registry.redhat.io` login and PAM issuer steps)  
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

1. **Install Podman and log in to the registry**

```bash
sudo dnf install -y podman
podman --version
sudo podman login registry.redhat.io
```

2. **Install and start Edge Manager services**

```bash
sudo dnf install -y flightctl-services
sudo systemctl enable --now flightctl.target
sudo systemctl list-units 'flightctl-*.service'
```

At this point, **Red Hat Edge Manager is installed and running**. The next step is only for **initial login bootstrap**.

3. **Bootstrap the first local admin user** (default OIDC via PAM issuer)

By default, the RHEL install uses the bundled `flightctl-pam-issuer` container as the OIDC identity source. You still need to create a local admin account there before the UI / CLI login in the next steps will work.

Yes: this is a required manual step on the RHEM host. Run the user/group creation commands here before moving on. The next step only uses that account to log in; it does **not** create the user for you.

Per product doc, run these commands on the RHEM host:

```bash
export RHEM_ADMIN_USER="CHANGEME-admin"
export RHEM_ADMIN_PASSWORD='CHANGEME-password'

sudo podman exec -i flightctl-pam-issuer groupadd flightctl-admin
sudo podman exec flightctl-pam-issuer adduser "$RHEM_ADMIN_USER"
sudo podman exec -i flightctl-pam-issuer sh -c "echo '${RHEM_ADMIN_USER}:${RHEM_ADMIN_PASSWORD}' | chpasswd"
sudo podman exec -i flightctl-pam-issuer usermod -aG flightctl-admin "$RHEM_ADMIN_USER"
```

Use that same username and password in the UI and `flightctl login` step below.

4. **CLI**

```bash
sudo dnf install -y flightctl-cli
flightctl version
flightctl login https://<RHEM_HOST>:3443 --username <USER> --password <PASS>
```

5. **UI** — `https://<RHEM_HOST>/` (TLS / self-signed: follow browser prompts). Use `https://<RHEM_HOST>:3443` for `flightctl` CLI/API login, not for the browser UI.

## Next (doc)

[Operating system images for Red Hat Edge Manager](https://docs.redhat.com/en/documentation/red_hat_edge_manager/1.0/) (same doc set).
