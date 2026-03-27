# `podman: command not found` During Edge Manager Install

## What it means

The host does not have Podman installed yet, but the install flow expects it for `registry.redhat.io` login and container-based components.

## How to fix it manually

Install Podman before the registry login step:

```bash
sudo dnf install -y podman
podman --version
sudo podman login registry.redhat.io
```
