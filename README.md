# Red Hat Edge Manager Demo Repo

This repo is for users who want to either:

- follow a manual Red Hat Edge Manager lab flow on their own hosts
- use this repo to stand up and run a full demo environment

## Choose a path

If you already have the required hosts or want to work through the setup yourself, start with the manual labs and follow them in order. For Lab 3, choose either the early-binding path or the late-binding path before you continue to Lab 4.

If you want this repo to create and configure the demo environment for you, start with [`automation/README.md`](automation/README.md).

## Manual labs

- [`labs/01-edge-manager-installation.md`](labs/01-edge-manager-installation.md) — Install Red Hat Edge Manager on RHEL
- [`labs/02-keycloak-integration.md`](labs/02-keycloak-integration.md) — Configure an existing Keycloak realm, users, and external OIDC integration
- [`labs/03a-bootc-earlybinding.md`](labs/03a-bootc-earlybinding.md) — Build an early-binding bootc image that already contains the enrollment configuration
- [`labs/03b-bootc-latebinding.md`](labs/03b-bootc-latebinding.md) — Build a late-binding bootc image and inject the enrollment configuration through cloud-init when you provision each device
- [`labs/04-enroll-device.md`](labs/04-enroll-device.md) — Boot a fresh device, approve enrollment, and verify the device is online
- [`labs/05-fleet-join.md`](labs/05-fleet-join.md) — Create a fleet and assign the device to it
- [`labs/06-managing-applications.md`](labs/06-managing-applications.md) — Build and deploy an application through Edge Manager
- [`labs/07-monitoring-support.md`](labs/07-monitoring-support.md) — Review monitoring and collect support data
- [`labs/08-security-compliance.md`](labs/08-security-compliance.md) — Review access, TLS, image sources, and patch posture
- [`labs/09-aap-integration.md`](labs/09-aap-integration.md) — Optional: configure Edge Manager to use Ansible Automation Platform for authentication instead of Keycloak
- [`labs/10-performance-optimization.md`](labs/10-performance-optimization.md) — Capture a baseline, tune the deployed application, and compare results

These labs are written as manual product walkthroughs. Replace placeholders such as `CHANGEME`, hostnames, registry paths, and passwords with values from your own environment before you run the commands.

## Automated demo

The automated path lives under [`automation/`](automation/README.md).

Common entry points:

- `make start-lab` — create and configure the full demo stack
- `make stop-lab` — remove the full demo stack
- `make start-demo-vms` — create only the base RHEL VMs for the manual lab path
- `make stop-demo-vms` — remove those base RHEL VMs
- `make build-image-early` — build the early-binding bootc image
- `make build-image-late` — build the late-binding bootc image and fetch the matching cloud-init user-data
- `make demo-early` — run the early-binding Labs 3 to 5 device flow after the stack is up
- `make demo-late` — run the late-binding Labs 3 to 5 device flow after the stack is up
- `make demo-app` — run the Lab 6 application flow after the device is enrolled

## Troubleshooting

If you hit a known issue while following the labs or running the automation, start with [`troubleshooting.md`](troubleshooting.md).

## Reference notes

[`prereqs/`](prereqs/README.md) contains supporting setup notes for the Proxmox automation path.
