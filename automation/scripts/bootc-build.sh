#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AUTOMATION_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
REPO_ROOT="$(cd "${AUTOMATION_DIR}/.." && pwd)"
ANSIBLE_DIR="${AUTOMATION_DIR}/ansible"
ANSIBLE_PLAYBOOK="${AUTOMATION_DIR}/.venv/bin/ansible-playbook"
ANSIBLE_INVENTORY="${AUTOMATION_DIR}/.venv/bin/ansible-inventory"
GROUP_VARS_FILE="${ANSIBLE_DIR}/group_vars/all.yml"
BOOTC_BINDING_MODE="${BOOTC_BINDING_MODE:-earlybinding}"
BOOTC_SOURCE_DIR="${REPO_ROOT}/bootc/${BOOTC_BINDING_MODE}"
BOOTC_INVENTORY_PATH="${ANSIBLE_DIR}/inventory/hosts.generated.yml"
BOOTC_TEMP_INVENTORY_DIR=""
extra_vars=()
BOOTC_BUILD_ISO_DEFAULT=false
BOOTC_BUILD_QCOW2_DEFAULT=true
BOOTC_BUILD_VMDK_DEFAULT=false
BOOTC_FETCH_ISO_DEFAULT=false
BOOTC_FETCH_QCOW2_DEFAULT=true
BOOTC_FETCH_VMDK_DEFAULT=false
BOOTC_FETCH_CLOUD_INIT_DEFAULT=false
BOOTC_UPDATE_CURRENT_DEFAULT=true

case "${BOOTC_BINDING_MODE}" in
  earlybinding|latebinding)
    if [[ "${BOOTC_BINDING_MODE}" == "latebinding" ]]; then
      BOOTC_FETCH_CLOUD_INIT_DEFAULT=true
    fi
    ;;
  vmdk-earlybinding|vmdk-latebinding)
    BOOTC_BUILD_QCOW2_DEFAULT=false
    BOOTC_BUILD_VMDK_DEFAULT=true
    BOOTC_FETCH_QCOW2_DEFAULT=false
    BOOTC_FETCH_VMDK_DEFAULT=true
    BOOTC_UPDATE_CURRENT_DEFAULT=false
    if [[ "${BOOTC_BINDING_MODE}" == "vmdk-latebinding" ]]; then
      BOOTC_FETCH_CLOUD_INIT_DEFAULT=true
    fi
    ;;
  *)
    echo "Unsupported BOOTC_BINDING_MODE: ${BOOTC_BINDING_MODE}. Use earlybinding, latebinding, vmdk-earlybinding, or vmdk-latebinding." >&2
    exit 1
    ;;
esac

echo "Using bootc source from ${BOOTC_SOURCE_DIR}"

cleanup() {
  if [[ -n "${BOOTC_TEMP_INVENTORY_DIR}" && -d "${BOOTC_TEMP_INVENTORY_DIR}" ]]; then
    rm -rf "${BOOTC_TEMP_INVENTORY_DIR}"
  fi
}
trap cleanup EXIT

inventory_has_rhem_hosts() {
  local inventory_path="$1"
  [[ -f "${inventory_path}" ]] || return 1
  "${ANSIBLE_INVENTORY}" -i "${inventory_path}" --list 2>/dev/null | \
    python3 -c 'import json, sys; data = json.load(sys.stdin); hosts = data.get("rhem_hosts", {}).get("hosts", []); raise SystemExit(0 if hosts else 1)'
}

synthesize_inventory_from_terraform() {
  BOOTC_TEMP_INVENTORY_DIR="$(mktemp -d "${TMPDIR:-/tmp}/bootc-inventory.XXXXXX")"
  local output_path="${BOOTC_TEMP_INVENTORY_DIR}/hosts.generated.yml"

  python3 - "${REPO_ROOT}" "${output_path}" <<'PY'
import json
import subprocess
import sys
from pathlib import Path

repo_root = Path(sys.argv[1])
output_path = Path(sys.argv[2])


def run_json(cmd):
    try:
        out = subprocess.check_output(cmd, text=True, stderr=subprocess.DEVNULL)
    except subprocess.CalledProcessError:
        return {}
    try:
        return json.loads(out)
    except json.JSONDecodeError:
        return {}


def list_workspaces(env_dir):
    try:
        out = subprocess.check_output(
            ["terraform", f"-chdir={env_dir}", "workspace", "list"],
            text=True,
            stderr=subprocess.DEVNULL,
        )
    except subprocess.CalledProcessError:
        return []
    workspaces = []
    for line in out.splitlines():
        line = line.replace("*", "").strip()
        if line:
          workspaces.append(line)
    return workspaces


def select_workspace(env_dir, workspace):
    try:
        subprocess.check_call(
            ["terraform", f"-chdir={env_dir}", "workspace", "select", workspace],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
        )
        return True
    except subprocess.CalledProcessError:
        return False


def flatten_first_ipv4(value):
    if isinstance(value, str):
        return "" if value.startswith("127.") or not value else value
    if isinstance(value, list):
        for item in value:
            candidate = flatten_first_ipv4(item)
            if candidate:
                return candidate
    return ""


def add_host(inventory, host_name, fqdn, ansible_host, groups):
    dns_name = fqdn.split(".", 1)[0] if fqdn and "." in fqdn else fqdn
    inventory["all"]["hosts"][host_name] = {
        "ansible_host": ansible_host,
        "ansible_user": "cloud-user",
        "fqdn": fqdn,
        "dns_name": dns_name,
    }
    for group in groups:
        inventory["all"]["children"].setdefault(group, {"hosts": {}})
        inventory["all"]["children"][group]["hosts"][host_name] = {}


inventory = {"all": {"hosts": {}, "children": {}}}
role_seen = set()

manual_env = repo_root / "automation/terraform/environments/manual-demo"
manual_outputs = run_json(["terraform", f"-chdir={manual_env}", "output", "-json"])
manual_names = manual_outputs.get("vm_names", {}).get("value", {})
manual_fqdns = manual_outputs.get("vm_fqdns", {}).get("value", {})
manual_ips = manual_outputs.get("vm_ipv4_addresses", {}).get("value", {})

for role, groups in {
    "rhem": ["managed_rhel_hosts", "rhem_hosts"],
    "keycloak": ["managed_rhel_hosts", "keycloak_hosts"],
}.items():
    host_name = manual_names.get(role, "")
    fqdn = manual_fqdns.get(role, "")
    ansible_host = flatten_first_ipv4(manual_ips.get(role, []))
    if host_name and fqdn and ansible_host:
        add_host(inventory, host_name, fqdn, ansible_host, groups)
        role_seen.add(role)

single_env = repo_root / "automation/terraform/environments/single-rhel9"
workspaces = list_workspaces(single_env)
workspace_before = workspaces[0] if workspaces else "default"
for line in subprocess.check_output(["terraform", f"-chdir={single_env}", "workspace", "list"], text=True, stderr=subprocess.DEVNULL).splitlines():
    if line.strip().startswith("*"):
        workspace_before = line.replace("*", "").strip()
        break

role_to_groups = {
    "edge-manager": ["managed_rhel_hosts", "rhem_hosts"],
    "rhem": ["managed_rhel_hosts", "rhem_hosts"],
    "keycloak": ["managed_rhel_hosts", "keycloak_hosts"],
    "satellite": ["managed_rhel_hosts", "satellite_hosts"],
    "dns": ["managed_rhel_hosts", "dns_hosts"],
    "aap": ["managed_rhel_hosts", "aap_controllers"],
}

for workspace in workspaces:
    if not workspace.startswith("single-"):
        continue
    role = workspace.removeprefix("single-")
    canonical_role = "rhem" if role == "edge-manager" else role
    if canonical_role in role_seen:
        continue
    if not select_workspace(single_env, workspace):
        continue
    outputs = run_json(["terraform", f"-chdir={single_env}", "output", "-json"])
    host_name = outputs.get("vm_name", {}).get("value", "")
    fqdn = outputs.get("vm_fqdn", {}).get("value", "")
    ansible_host = flatten_first_ipv4(outputs.get("vm_ipv4_addresses", {}).get("value", []))
    groups = role_to_groups.get(role, [])
    if host_name and fqdn and ansible_host and groups:
        add_host(inventory, host_name, fqdn, ansible_host, groups)
        role_seen.add(canonical_role)

select_workspace(single_env, workspace_before)

if not inventory["all"]["children"].get("rhem_hosts", {}).get("hosts"):
    raise SystemExit("No usable rhem host was found in Terraform state. Start the manual or demo environment first.")

lines = ["all:", "  hosts:"]
for host_name, hostvars in inventory["all"]["hosts"].items():
    lines.append(f"    {host_name}:")
    for key, value in hostvars.items():
        lines.append(f"      {key}: {value}")
lines.append("  children:")
for group_name, group_data in inventory["all"]["children"].items():
    lines.append(f"    {group_name}:")
    lines.append("      hosts:")
    for host_name in group_data["hosts"]:
        lines.append(f"        {host_name}: {{}}")

output_path.write_text("\n".join(lines) + "\n", encoding="ascii")
PY

  BOOTC_INVENTORY_PATH="${output_path}"
}

if ! inventory_has_rhem_hosts "${BOOTC_INVENTORY_PATH}"; then
  synthesize_inventory_from_terraform
fi

if ! inventory_has_rhem_hosts "${BOOTC_INVENTORY_PATH}"; then
  echo "No usable Ansible inventory was found for the bootc build." >&2
  exit 1
fi

extra_vars+=(-e "bootc_binding=${BOOTC_BINDING_MODE}")
extra_vars+=(-e "bootc_build_iso=${BOOTC_BUILD_ISO:-${BOOTC_BUILD_ISO_DEFAULT}}")
extra_vars+=(-e "bootc_build_qcow2=${BOOTC_BUILD_QCOW2:-${BOOTC_BUILD_QCOW2_DEFAULT}}")
extra_vars+=(-e "bootc_build_vmdk=${BOOTC_BUILD_VMDK:-${BOOTC_BUILD_VMDK_DEFAULT}}")

if [[ -n "${BOOTC_FORCE_REBUILD:-}" ]]; then
  extra_vars+=(-e "bootc_force_rebuild=${BOOTC_FORCE_REBUILD}")
fi

cd "${ANSIBLE_DIR}"
"${ANSIBLE_PLAYBOOK}" -i "${BOOTC_INVENTORY_PATH}" playbooks/bootc_image_build.yml "${extra_vars[@]}"

BOOTC_WORKSPACE_ROOT="/var/lib/rhem-demo/bootc"
if [[ -f "${GROUP_VARS_FILE}" ]]; then
  configured_workspace="$(sed -n "s/^bootc_workspace_dir:[[:space:]]*//p" "${GROUP_VARS_FILE}" | tail -n 1 | tr -d "\"'")"
  if [[ -n "${configured_workspace}" ]]; then
    BOOTC_WORKSPACE_ROOT="${configured_workspace}"
  fi
fi
BOOTC_WORKSPACE_DIR="${BOOTC_WORKSPACE_ROOT}/${BOOTC_BINDING_MODE}"

read -r RHEM_HOST RHEM_ADDR < <(
  "${ANSIBLE_INVENTORY}" -i "${BOOTC_INVENTORY_PATH}" --list | \
    python3 -c 'import json, sys; data = json.load(sys.stdin); host = data["rhem_hosts"]["hosts"][0]; print(host, data["_meta"]["hostvars"][host]["ansible_host"])'
)

ARTIFACT_DIR="${AUTOMATION_DIR}/artifacts/bootc/${BOOTC_BINDING_MODE}/${RHEM_HOST}"
CURRENT_ARTIFACT_DIR="${AUTOMATION_DIR}/artifacts/bootc/current/${RHEM_HOST}"
mkdir -p "${ARTIFACT_DIR}" "${CURRENT_ARTIFACT_DIR}"

fetch_remote_artifact() {
  local remote_path="$1"
  local local_path="$2"
  rsync \
    -a \
    --partial \
    --inplace \
    --rsync-path="sudo rsync" \
    -e "ssh -i ${HOME}/.ssh/redhat-edge-manager-demo -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null" \
    "cloud-user@${RHEM_ADDR}:${remote_path}" \
    "${local_path}"
}

if [[ "${BOOTC_FETCH_ISO:-${BOOTC_FETCH_ISO_DEFAULT}}" == "true" ]]; then
  fetch_remote_artifact \
    "${BOOTC_WORKSPACE_DIR}/output/bootiso/install.iso" \
    "${ARTIFACT_DIR}/install.iso"
fi

if [[ "${BOOTC_FETCH_QCOW2:-${BOOTC_FETCH_QCOW2_DEFAULT}}" == "true" ]]; then
  fetch_remote_artifact \
    "${BOOTC_WORKSPACE_DIR}/output/qcow2/disk.qcow2" \
    "${ARTIFACT_DIR}/disk.qcow2"
fi

if [[ "${BOOTC_FETCH_VMDK:-${BOOTC_FETCH_VMDK_DEFAULT}}" == "true" ]]; then
  fetch_remote_artifact \
    "${BOOTC_WORKSPACE_DIR}/output/vmdk/disk.vmdk" \
    "${ARTIFACT_DIR}/disk.vmdk"
fi

if [[ "${BOOTC_FETCH_CLOUD_INIT:-${BOOTC_FETCH_CLOUD_INIT_DEFAULT}}" == "true" ]]; then
  fetch_remote_artifact \
    "${BOOTC_WORKSPACE_DIR}/cloud-init.user-data.yaml" \
    "${ARTIFACT_DIR}/cloud-init.user-data.yaml"
fi

printf '%s\n' "${BOOTC_BINDING_MODE}" > "${ARTIFACT_DIR}/binding-mode.txt"

if [[ "${BOOTC_UPDATE_CURRENT:-${BOOTC_UPDATE_CURRENT_DEFAULT}}" == "true" ]]; then
  rm -f "${CURRENT_ARTIFACT_DIR}/disk.qcow2" "${CURRENT_ARTIFACT_DIR}/install.iso" "${CURRENT_ARTIFACT_DIR}/disk.vmdk" "${CURRENT_ARTIFACT_DIR}/cloud-init.user-data.yaml" "${CURRENT_ARTIFACT_DIR}/binding-mode.txt"

  if [[ -f "${ARTIFACT_DIR}/disk.qcow2" ]]; then
    cp "${ARTIFACT_DIR}/disk.qcow2" "${CURRENT_ARTIFACT_DIR}/disk.qcow2"
  fi

  if [[ -f "${ARTIFACT_DIR}/install.iso" ]]; then
    cp "${ARTIFACT_DIR}/install.iso" "${CURRENT_ARTIFACT_DIR}/install.iso"
  fi

  if [[ -f "${ARTIFACT_DIR}/disk.vmdk" ]]; then
    cp "${ARTIFACT_DIR}/disk.vmdk" "${CURRENT_ARTIFACT_DIR}/disk.vmdk"
  fi

  if [[ -f "${ARTIFACT_DIR}/cloud-init.user-data.yaml" ]]; then
    cp "${ARTIFACT_DIR}/cloud-init.user-data.yaml" "${CURRENT_ARTIFACT_DIR}/cloud-init.user-data.yaml"
  fi

  printf '%s\n' "${BOOTC_BINDING_MODE}" > "${CURRENT_ARTIFACT_DIR}/binding-mode.txt"
fi

echo "Fetched bootc artifacts into ${ARTIFACT_DIR}"
if [[ "${BOOTC_UPDATE_CURRENT:-${BOOTC_UPDATE_CURRENT_DEFAULT}}" == "true" ]]; then
  echo "Updated current bootc artifacts in ${CURRENT_ARTIFACT_DIR}"
fi
