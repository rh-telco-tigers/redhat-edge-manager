#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AUTOMATION_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
ANSIBLE_DIR="${AUTOMATION_DIR}/ansible"
ANSIBLE_PLAYBOOK="${AUTOMATION_DIR}/.venv/bin/ansible-playbook"
DEVICE_TF_DIR="${AUTOMATION_DIR}/terraform/environments/device-vm"

extra_vars=()
device_name="${DEVICE_NAME:-}"
device_site="${DEVICE_SITE:-}"
device_label_kvs="${DEVICE_LABEL_KVS:-}"
stored_device_label_kvs_csv=""

slugify() {
  printf '%s' "$1" \
    | tr '[:upper:]' '[:lower:]' \
    | sed -E 's/[^a-z0-9]+/-/g; s/^-+//; s/-+$//; s/-{2,}/-/g'
}

device_metadata_path() {
  local workspace_name="$1"
  printf '%s/.device-metadata/%s.env' "$DEVICE_TF_DIR" "$workspace_name"
}

merge_csv() {
  local result=""
  local item source
  local -a items

  for source in "$@"; do
    [[ -n "$source" ]] || continue
    IFS=',' read -r -a items <<< "$source"
    for item in "${items[@]}"; do
      [[ -n "$item" ]] || continue
      if [[ -n "$result" ]]; then
        result+=","
      fi
      result+="$item"
    done
  done

  printf '%s' "$result"
}

if [[ -n "$device_name" ]]; then
  workspace_name="device-$(slugify "$device_name")"
  metadata_path="$(device_metadata_path "$workspace_name")"
  if [[ -f "$metadata_path" ]]; then
    # shellcheck source=/dev/null
    source "$metadata_path"
    stored_device_label_kvs_csv="${DEVICE_LABEL_KVS_CSV:-}"
  fi
fi

explicit_label_kvs_csv=""
if [[ -n "$device_site" ]]; then
  explicit_label_kvs_csv="site=$device_site"
fi
if [[ -n "$device_label_kvs" ]]; then
  explicit_label_kvs_csv="$(merge_csv "$explicit_label_kvs_csv" "$(printf '%s' "$device_label_kvs" | tr ' ' ',')")"
fi
effective_label_kvs_csv="$(merge_csv "$stored_device_label_kvs_csv" "$explicit_label_kvs_csv")"

if [[ -n "${WAIT_FOR_PENDING:-}" ]]; then
  extra_vars+=(-e "enrollment_wait_for_pending=${WAIT_FOR_PENDING}")
fi

if [[ -n "${WAIT_TIMEOUT_SECONDS:-}" ]]; then
  extra_vars+=(-e "enrollment_pending_timeout_seconds=${WAIT_TIMEOUT_SECONDS}")
fi

if [[ -n "${WAIT_POLL_INTERVAL_SECONDS:-}" ]]; then
  extra_vars+=(-e "enrollment_pending_poll_interval_seconds=${WAIT_POLL_INTERVAL_SECONDS}")
fi

if [[ -n "$effective_label_kvs_csv" ]]; then
  extra_vars+=(-e "device_enrollment_label_kvs_csv=${effective_label_kvs_csv}")
fi

cd "${ANSIBLE_DIR}"
if (( ${#extra_vars[@]} > 0 )); then
  "${ANSIBLE_PLAYBOOK}" playbooks/approve_enrollment.yml "${extra_vars[@]}"
else
  "${ANSIBLE_PLAYBOOK}" playbooks/approve_enrollment.yml
fi
