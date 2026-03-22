# RHEM EAP demo repo

This repo now has two clear paths:

- `labs/` are manual step-by-step walkthroughs.
- `automation/` contains both the fully automated stack and a Terraform-only manual-demo VM flow.

If you want the fully automated management stack, start with [`automation/README.md`](automation/README.md) and use `make up` / `make down`.

If you want to follow the labs manually but still have Terraform create the base RHEL VMs for Labs 1 and 2, use `make rhel-vms-up` / `make rhel-vms-down`.

The full automation path now also includes a dedicated Satellite VM in the demo stack, and the later device labs use Satellite as the registry/content source while Edge Manager remains the device control plane.

## Steps

1. [`labs/01-edge-manager-installation.md`](labs/01-edge-manager-installation.md) — Install RHEM on RHEL
2. [`labs/02-keycloak-integration.md`](labs/02-keycloak-integration.md) — Configure an existing Keycloak realm, users, and external OIDC integration
3. [`labs/03-bootc-images.md`](labs/03-bootc-images.md) — Build the Edge Manager bootc image, publish it through Satellite, and generate the unattended installer ISO
4. [`labs/04-enroll-device.md`](labs/04-enroll-device.md) — Boot a fresh device from that ISO, approve enrollment, and verify the device is online
5. [`labs/05-fleet-join.md`](labs/05-fleet-join.md) — Create a Fleet that points at the Satellite-hosted bootc image
6. [`labs/06-managing-applications.md`](labs/06-managing-applications.md) — Build a demo application image, package it as a quadlet wrapper image, and deploy it through the demo fleet
7. [`labs/07-monitoring-support.md`](labs/07-monitoring-support.md) — Review monitoring and collect support data
8. [`labs/08-security-compliance.md`](labs/08-security-compliance.md) — Review access, TLS, image sources, and patch posture
9. [`labs/09-performance-optimization.md`](labs/09-performance-optimization.md) — Capture a baseline, tune the deployed application, and compare results

## Conventions

- **`labs/*.md`** — Step-by-step Markdown guides. Copy commands from fenced blocks.
- Replace placeholders like `CHANGEME`, registry URLs, and hostnames before running.
- `automation/` is where runnable Terraform, Ansible, and Make targets live.
- `prereqs/` is now reference-only for optional infrastructure notes and alternate deployment paths.
- For the fully automated Labs 3 to 5 path after `make up`, use `make device-demo`.
- For the Lab 6 application-management path after the device is already enrolled and in the fleet, use `make app-demo`.

## Optional: render Markdoc

If you add a Markdoc site later, use the root `markdoc.config.mjs` and point your bundler at the Markdown files under `labs/`.
