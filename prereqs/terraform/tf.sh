#!/usr/bin/env bash
# Run terraform with optional prereqs/terraform/.env (gitignored).
# Credentials: PROXMOX_VE_API_TOKEN — or PROXMOX_VE_USERNAME + PROXMOX_VE_PASSWORD
set -euo pipefail
cd "$(dirname "$0")"

if [[ -f .env ]]; then
  set -a
  # shellcheck source=/dev/null
  source .env
  set +a
fi

if [[ -n "${PROXMOX_VE_API_TOKEN:-}" ]]; then
  :
elif [[ -n "${PROXMOX_VE_USERNAME:-}" && -n "${PROXMOX_VE_PASSWORD:-}" ]]; then
  :
else
  echo "Proxmox credentials missing." >&2
  echo "  Set PROXMOX_VE_API_TOKEN, or PROXMOX_VE_USERNAME + PROXMOX_VE_PASSWORD" >&2
  echo "  (optional) copy .env.example to .env in this directory — see prereqs/docs/01-proxmox-terraform.md" >&2
  exit 1
fi

export PROXMOX_VE_INSECURE="${PROXMOX_VE_INSECURE:-true}"

exec terraform "$@"
