#!/usr/bin/env bash
# Apply using Proxmox username/password or API token via provider env vars.
# See: https://registry.terraform.io/providers/bpg/proxmox/latest/docs
set -euo pipefail
cd "$(dirname "$0")"

if [[ -f .env ]]; then
  set -a
  # shellcheck source=/dev/null
  source .env
  set +a
fi

if [[ -z "${PROXMOX_VE_API_TOKEN:-}" ]]; then
  : "${PROXMOX_VE_USERNAME:?Set PROXMOX_VE_USERNAME e.g. root@pam, or set PROXMOX_VE_API_TOKEN}"
  : "${PROXMOX_VE_PASSWORD:?Set PROXMOX_VE_PASSWORD when not using API token}"
fi

export PROXMOX_VE_INSECURE="${PROXMOX_VE_INSECURE:-true}"

terraform init -backend=false
terraform apply -auto-approve "$@"
