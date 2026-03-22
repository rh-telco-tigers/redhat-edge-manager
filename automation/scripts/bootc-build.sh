#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AUTOMATION_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
ANSIBLE_DIR="${AUTOMATION_DIR}/ansible"
ANSIBLE_PLAYBOOK="${AUTOMATION_DIR}/.venv/bin/ansible-playbook"
ANSIBLE_INVENTORY="${AUTOMATION_DIR}/.venv/bin/ansible-inventory"
GROUP_VARS_FILE="${ANSIBLE_DIR}/group_vars/all.yml"

cd "${ANSIBLE_DIR}"
"${ANSIBLE_PLAYBOOK}" playbooks/bootc_image_build.yml

BOOTC_WORKSPACE_DIR="/var/lib/rhem-demo/bootc"
if [[ -f "${GROUP_VARS_FILE}" ]]; then
  configured_workspace="$(sed -n "s/^bootc_workspace_dir:[[:space:]]*//p" "${GROUP_VARS_FILE}" | tail -n 1 | tr -d "\"'")"
  if [[ -n "${configured_workspace}" ]]; then
    BOOTC_WORKSPACE_DIR="${configured_workspace}"
  fi
fi

read -r RHEM_HOST RHEM_ADDR < <(
  "${ANSIBLE_INVENTORY}" -i "${ANSIBLE_DIR}/inventory/hosts.generated.yml" --list | \
    python3 -c 'import json, sys; data = json.load(sys.stdin); host = data["rhem_hosts"]["hosts"][0]; print(host, data["_meta"]["hostvars"][host]["ansible_host"])'
)

ARTIFACT_DIR="${AUTOMATION_DIR}/artifacts/bootc/${RHEM_HOST}"
mkdir -p "${ARTIFACT_DIR}"

scp \
  -i "${HOME}/.ssh/redhat-edge-manager-demo" \
  -o StrictHostKeyChecking=no \
  -o UserKnownHostsFile=/dev/null \
  "cloud-user@${RHEM_ADDR}:${BOOTC_WORKSPACE_DIR}/output/bootiso/install.iso" \
  "${ARTIFACT_DIR}/install.iso"
