# Red Hat Edge Manager Demo Repo

This repo is for users who want to either:

- follow a manual Red Hat Edge Manager lab flow on their own hosts
- use this repo to stand up and run a full demo environment

## Choose a path

If you already have the required hosts or want to work through the setup yourself, start with the manual labs and follow them in order.

If you want this repo to create and configure the demo environment for you, start with [`automation/README.md`](automation/README.md).

## Manual labs

Start with:

1. [`labs/01-edge-manager-installation.md`](labs/01-edge-manager-installation.md) — Install Red Hat Edge Manager on RHEL

Then choose one authentication integration path:

- [`labs/02-keycloak-integration.md`](labs/02-keycloak-integration.md) — Configure an existing Keycloak realm, users, and external OIDC integration
- [`labs/02a-aap-integration.md`](labs/02a-aap-integration.md) — Configure Edge Manager to use Ansible Automation Platform for authentication

Then continue with:

3. [`labs/03-bootc-images.md`](labs/03-bootc-images.md) — Build the bootc image, publish it through Satellite, and generate the installer artifact
4. [`labs/04-enroll-device.md`](labs/04-enroll-device.md) — Boot a fresh device, approve enrollment, and verify the device is online
5. [`labs/05-fleet-join.md`](labs/05-fleet-join.md) — Create a fleet and assign the device to it
6. [`labs/06-managing-applications.md`](labs/06-managing-applications.md) — Build and deploy an application through Edge Manager
7. [`labs/07-monitoring-support.md`](labs/07-monitoring-support.md) — Review monitoring and collect support data
8. [`labs/08-security-compliance.md`](labs/08-security-compliance.md) — Review access, TLS, image sources, and patch posture
9. [`labs/09-performance-optimization.md`](labs/09-performance-optimization.md) — Capture a baseline, tune the deployed application, and compare results

These labs are written as manual product walkthroughs. Replace placeholders such as `CHANGEME`, hostnames, registry paths, and passwords with values from your own environment before you run the commands.

## Automated demo

The automated path lives under [`automation/`](automation/README.md).

Common entry points:

- `make up` — create and configure the full demo stack
- `make down` — remove the full demo stack
- `make rhel-vms-up` — create only the base RHEL VMs for the manual lab path
- `make rhel-vms-down` — remove those base RHEL VMs
- `make device-demo` — run the Labs 3 to 5 device flow after the stack is up
- `make app-demo` — run the Lab 6 application flow after the device is enrolled

## Reference notes

[`prereqs/`](prereqs/README.md) contains supporting reference material for optional infrastructure notes and alternate deployment paths.
