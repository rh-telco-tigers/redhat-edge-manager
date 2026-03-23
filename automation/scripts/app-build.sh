#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AUTOMATION_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
REPO_ROOT="$(cd "${AUTOMATION_DIR}/.." && pwd)"
ANSIBLE_DIR="${AUTOMATION_DIR}/ansible"
ANSIBLE_PLAYBOOK="${AUTOMATION_DIR}/.venv/bin/ansible-playbook"
DEMO_APPLICATION_NAME="${DEMO_APPLICATION_NAME:-hello-web}"

echo "Using application source from ${REPO_ROOT}/applications/${DEMO_APPLICATION_NAME}"

cd "${ANSIBLE_DIR}"
"${ANSIBLE_PLAYBOOK}" playbooks/application_build.yml
