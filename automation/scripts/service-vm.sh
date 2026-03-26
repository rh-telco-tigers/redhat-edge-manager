#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/../.." && pwd)"
env_dir="$repo_root/automation/terraform/environments/single-rhel9"
ansible_dir="$repo_root/automation/ansible"
ansible_playbook="${repo_root}/automation/.venv/bin/ansible-playbook"

role="${ROLE:-}"
action="${ACTION:-start}"

if [[ -z "$role" ]]; then
  echo "ROLE is required (keycloak or satellite)." >&2
  exit 1
fi

case "$role" in
  keycloak)
    workspace_name="${TF_WORKSPACE_NAME:-single-keycloak}"
    resource_pool_id="${RESOURCE_POOL_ID:-rhem-eap-single-keycloak}"
    vm_id="${VM_ID:-201}"
    vm_name="${VM_NAME:-rhem-keycloak-standalone-01}"
    dns_name="${DNS_NAME:-keycloak}"
    ipv4_cidr="${IPV4_CIDR:-192.168.4.201/22}"
    vm_tags="${VM_TAGS:-service-keycloak}"
playbook="playbooks/keycloak_install.yml"
    prepare_playbook="playbooks/rhel_prepare.yml"
    inventory_group="keycloak_hosts"
    ansible_extra_args=()
    ;;
  satellite)
    workspace_name="${TF_WORKSPACE_NAME:-single-satellite}"
    resource_pool_id="${RESOURCE_POOL_ID:-rhem-eap-single-satellite}"
    vm_id="${VM_ID:-203}"
    vm_name="${VM_NAME:-rhem-satellite-standalone-01}"
    dns_name="${DNS_NAME:-satellite}"
    ipv4_cidr="${IPV4_CIDR:-192.168.4.203/22}"
    vm_tags="${VM_TAGS:-service-satellite}"
    playbook="playbooks/satellite_install.yml"
    prepare_playbook="playbooks/rhel_prepare.yml"
    inventory_group="satellite_hosts"
    ansible_extra_args=(-e "satellite_install_enabled=true")
    ;;
  *)
    echo "Unsupported ROLE: $role" >&2
    exit 1
    ;;
esac

if [[ "$action" == "stop" ]]; then
  TF_WORKSPACE_NAME="$workspace_name" \
  RESOURCE_POOL_ID="$resource_pool_id" \
  ROLE="$role" \
  VM_ID="$vm_id" \
  VM_NAME="$vm_name" \
  DNS_NAME="$dns_name" \
  IPV4_CIDR="$ipv4_cidr" \
  VM_TAGS="$vm_tags" \
  ACTION=destroy \
  "$repo_root/automation/scripts/create-rhel9.sh"
  exit 0
fi

TF_WORKSPACE_NAME="$workspace_name" \
RESOURCE_POOL_ID="$resource_pool_id" \
ROLE="$role" \
VM_ID="$vm_id" \
VM_NAME="$vm_name" \
DNS_NAME="$dns_name" \
IPV4_CIDR="$ipv4_cidr" \
VM_TAGS="$vm_tags" \
ACTION=apply \
"$repo_root/automation/scripts/create-rhel9.sh"

python3 - "$env_dir" "$workspace_name" "$ipv4_cidr" <<'PY' > /tmp/service-vm-outputs.env
import json
import subprocess
import sys

env_dir = sys.argv[1]
workspace = sys.argv[2]
ipv4_cidr = sys.argv[3]
subprocess.check_call(
    ["terraform", f"-chdir={env_dir}", "workspace", "select", workspace],
    stdout=subprocess.DEVNULL,
    stderr=subprocess.DEVNULL,
)
raw = subprocess.check_output(["terraform", f"-chdir={env_dir}", "output", "-json"], text=True)
data = json.loads(raw)

vm_id = data["vm_id"]["value"]
vm_name = data["vm_name"]["value"]
fqdn = data["vm_fqdn"]["value"]
ipv4_addresses = []
if "vm_ipv4_addresses" in data and data["vm_ipv4_addresses"].get("value"):
    ipv4_addresses = data["vm_ipv4_addresses"]["value"]
ansible_host = ""
for candidate in ipv4_addresses:
    values = candidate if isinstance(candidate, list) else [candidate]
    for value in values:
        if value != "127.0.0.1":
            ansible_host = value
            break
    if ansible_host:
        break

if not ansible_host and ipv4_cidr:
    ansible_host = ipv4_cidr.split("/", 1)[0]

if not ansible_host:
    raise SystemExit("No usable IPv4 address was available from Terraform output or the configured static CIDR.")

print(f"VM_ID={vm_id}")
print(f"VM_NAME={vm_name}")
print(f"FQDN={fqdn}")
print(f"ANSIBLE_HOST={ansible_host}")
PY

# shellcheck disable=SC1091
source /tmp/service-vm-outputs.env

inventory_dir="$(mktemp -d "${TMPDIR:-/tmp}/service-vm-inventory.XXXXXX")"
inventory_file="$inventory_dir/inventory.yml"
trap 'rm -rf "$inventory_dir" /tmp/service-vm-outputs.env' EXIT

cat > "$inventory_file" <<EOF
all:
  hosts:
    $VM_NAME:
      ansible_host: $ANSIBLE_HOST
      ansible_user: cloud-user
      fqdn: $FQDN
      dns_name: $dns_name
  children:
    managed_rhel_hosts:
      hosts:
        $VM_NAME: {}
    $inventory_group:
      hosts:
        $VM_NAME: {}
EOF

cd "$ansible_dir"
playbook_cmd=("$ansible_playbook" -i "$inventory_file")
if [[ ${#ansible_extra_args[@]:-0} -gt 0 ]]; then
  playbook_cmd+=("${ansible_extra_args[@]}")
fi
playbook_cmd+=("$prepare_playbook" "$playbook")
"${playbook_cmd[@]}"
