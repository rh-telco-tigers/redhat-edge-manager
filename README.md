# RHEM EAP demo repo

This repo now has two clear paths:

- `labs/` are manual step-by-step walkthroughs.
- `automation/` is the runnable environment setup and teardown path.

If you want the automated management stack, start with [`automation/README.md`](automation/README.md) and use `make up` / `make down`.

## Steps

1. [`labs/01-edge-manager-installation`](labs/01-edge-manager-installation) — Install RHEM on RHEL
2. [`labs/02-keycloak-integration`](labs/02-keycloak-integration) — Add a lightweight Keycloak VM, realm, users, and external OIDC integration
3. [`labs/03-bootc-images`](labs/03-bootc-images) — Build base + app bootc images and publish them
4. [`labs/04-enroll-device`](labs/04-enroll-device) — Onboard a device
5. [`labs/05-fleet-join`](labs/05-fleet-join) — Create a fleet and roll a device onto the app image
6. [`labs/06-managing-applications`](labs/06-managing-applications) — Deploy application workloads
7. [`labs/07-monitoring-support`](labs/07-monitoring-support) — Review monitoring and collect support data
8. [`labs/08-security-compliance`](labs/08-security-compliance) — Work through security and compliance checks
9. [`labs/09-performance-optimization`](labs/09-performance-optimization) — Review performance and optimization items

## Conventions

- **`lab.md`** — Step-by-step Markdown guide. Copy commands from fenced blocks.
- Replace placeholders like `CHANGEME`, registry URLs, and hostnames before running.
- `automation/` is where runnable Terraform, Ansible, and Make targets live.

## Optional: render Markdoc

If you add a Markdoc site later, use the root `markdoc.config.mjs` and point your bundler at these `lab.md` files.
