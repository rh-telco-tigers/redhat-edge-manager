#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AUTOMATION_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
ANSIBLE_DIR="${AUTOMATION_DIR}/ansible"
ANSIBLE_PLAYBOOK="${AUTOMATION_DIR}/.venv/bin/ansible-playbook"

extra_vars=()

if [[ -n "${WAIT_FOR_PENDING:-}" ]]; then
  extra_vars+=(-e "enrollment_wait_for_pending=${WAIT_FOR_PENDING}")
fi

if [[ -n "${WAIT_TIMEOUT_SECONDS:-}" ]]; then
  extra_vars+=(-e "enrollment_pending_timeout_seconds=${WAIT_TIMEOUT_SECONDS}")
fi

if [[ -n "${WAIT_POLL_INTERVAL_SECONDS:-}" ]]; then
  extra_vars+=(-e "enrollment_pending_poll_interval_seconds=${WAIT_POLL_INTERVAL_SECONDS}")
fi

cd "${ANSIBLE_DIR}"
if (( ${#extra_vars[@]} > 0 )); then
  "${ANSIBLE_PLAYBOOK}" playbooks/approve_enrollment.yml "${extra_vars[@]}"
else
  "${ANSIBLE_PLAYBOOK}" playbooks/approve_enrollment.yml
fi
