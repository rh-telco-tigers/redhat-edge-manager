#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AUTOMATION_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
ANSIBLE_DIR="${AUTOMATION_DIR}/ansible"
ANSIBLE_PLAYBOOK="${AUTOMATION_DIR}/.venv/bin/ansible-playbook"
ANSIBLE_INVENTORY="${AUTOMATION_DIR}/.venv/bin/ansible-inventory"
GROUP_VARS_FILE="${ANSIBLE_DIR}/group_vars/all.yml"
extra_vars=()

if [[ -n "${BOOTC_FORCE_REBUILD:-}" ]]; then
  extra_vars+=(-e "bootc_force_rebuild=${BOOTC_FORCE_REBUILD}")
fi

if [[ -n "${BOOTC_BUILD_QCOW2:-}" ]]; then
  extra_vars+=(-e "bootc_build_qcow2=${BOOTC_BUILD_QCOW2}")
fi

if [[ -n "${BOOTC_BUILD_ISO:-}" ]]; then
  extra_vars+=(-e "bootc_build_iso=${BOOTC_BUILD_ISO}")
fi

cd "${ANSIBLE_DIR}"
if (( ${#extra_vars[@]} > 0 )); then
  "${ANSIBLE_PLAYBOOK}" playbooks/bootc_image_build.yml "${extra_vars[@]}"
else
  "${ANSIBLE_PLAYBOOK}" playbooks/bootc_image_build.yml
fi

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

fetch_remote_artifact() {
  local remote_path="$1"
  local local_path="$2"
  rsync \
    -a \
    --partial \
    --inplace \
    -e "ssh -i ${HOME}/.ssh/redhat-edge-manager-demo -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null" \
    "cloud-user@${RHEM_ADDR}:${remote_path}" \
    "${local_path}"
}

if [[ "${BOOTC_FETCH_ISO:-false}" == "true" ]]; then
  fetch_remote_artifact \
    "${BOOTC_WORKSPACE_DIR}/output/bootiso/install.iso" \
    "${ARTIFACT_DIR}/install.iso"
fi

if [[ "${BOOTC_FETCH_QCOW2:-true}" == "true" ]]; then
  fetch_remote_artifact \
    "${BOOTC_WORKSPACE_DIR}/output/qcow2/disk.qcow2" \
    "${ARTIFACT_DIR}/disk.qcow2"
fi
