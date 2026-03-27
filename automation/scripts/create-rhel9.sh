#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/../.." && pwd)"
env_dir="$repo_root/automation/terraform/environments/single-rhel9"

"$repo_root/automation/scripts/init-files.sh"

role="${ROLE:-generic}"
workspace_name="${TF_WORKSPACE_NAME:-single-${role}}"
vm_id="${VM_ID:-}"
vm_name="${VM_NAME:-}"
dns_name="${DNS_NAME:-}"
cores="${VM_CORES:-}"
memory_mb="${VM_MEMORY_MB:-}"
disk_gb="${VM_DISK_GB:-}"
ipv4_mode="${IPV4_MODE:-static}"
ipv4_cidr="${IPV4_CIDR:-}"
ipv4_gateway="${IPV4_GATEWAY:-192.168.4.1}"
dns_servers="${DNS_SERVERS:-1.1.1.1,8.8.8.8}"
description="${VM_DESCRIPTION:-}"
extra_tags="${VM_TAGS:-}"
resource_pool_id="${RESOURCE_POOL_ID:-}"
action="${ACTION:-apply}"

case "$role" in
  edge-manager)
    cores="${cores:-4}"
    memory_mb="${memory_mb:-16384}"
    disk_gb="${disk_gb:-80}"
    vm_name="${vm_name:-rhem}"
    dns_name="${dns_name:-rhem}"
    description="${description:-Red Hat Edge Manager host}"
    ;;
  keycloak)
    cores="${cores:-2}"
    memory_mb="${memory_mb:-4096}"
    disk_gb="${disk_gb:-40}"
    vm_name="${vm_name:-rhem-keycloak-01}"
    dns_name="${dns_name:-keycloak}"
    description="${description:-Keycloak identity provider host}"
    ;;
  satellite)
    cores="${cores:-4}"
    memory_mb="${memory_mb:-20480}"
    disk_gb="${disk_gb:-500}"
    vm_name="${vm_name:-rhem-satellite-01}"
    dns_name="${dns_name:-satellite}"
    description="${description:-Red Hat Satellite host}"
    ;;
  dns)
    cores="${cores:-2}"
    memory_mb="${memory_mb:-4096}"
    disk_gb="${disk_gb:-30}"
    vm_name="${vm_name:-rhem-dns-01}"
    dns_name="${dns_name:-dns}"
    description="${description:-PowerDNS host}"
    ;;
  aap)
    cores="${cores:-4}"
    memory_mb="${memory_mb:-16384}"
    disk_gb="${disk_gb:-80}"
    vm_name="${vm_name:-rhem-aap-01}"
    dns_name="${dns_name:-aap}"
    description="${description:-Ansible Automation Platform host}"
    ;;
  *)
    cores="${cores:-2}"
    memory_mb="${memory_mb:-4096}"
    disk_gb="${disk_gb:-40}"
    vm_name="${vm_name:-rhel9-generic-01}"
    dns_name="${dns_name:-$vm_name}"
    description="${description:-Generic RHEL 9 cloud image VM}"
    ;;
esac

if [[ -z "$vm_id" ]]; then
  echo "VM_ID is required. Example: make create-vm ROLE=keycloak VM_ID=121 IPV4_CIDR=192.168.4.121/22" >&2
  exit 1
fi

if [[ "$ipv4_mode" != "dhcp" && -z "$ipv4_cidr" ]]; then
  echo "IPV4_CIDR is required unless IPV4_MODE=dhcp." >&2
  exit 1
fi

dns_args=()
IFS=',' read -r -a dns_server_array <<< "$dns_servers"
dns_hcl="["
for server in "${dns_server_array[@]}"; do
  [[ -n "$server" ]] || continue
  if [[ "$dns_hcl" != "[" ]]; then
    dns_hcl+=", "
  fi
  dns_hcl+="\"$server\""
done
dns_hcl+="]"

tag_args=()
if [[ -n "$extra_tags" ]]; then
  IFS=',' read -r -a tag_array <<< "$extra_tags"
  for tag in "${tag_array[@]}"; do
    [[ -n "$tag" ]] || continue
    if [[ ${#tag_args[@]} -eq 0 ]]; then
      tag_args=("\"$tag\"")
    else
      tag_args+=(", \"$tag\"")
    fi
  done
fi

tag_hcl="[]"
if [[ ${#tag_args[@]} -gt 0 ]]; then
  tag_hcl="[${tag_args[*]}]"
fi

terraform -chdir="$env_dir" init -input=false >/dev/null
terraform -chdir="$env_dir" workspace select "$workspace_name" >/dev/null 2>&1 || \
  terraform -chdir="$env_dir" workspace new "$workspace_name" >/dev/null

cmd=("$env_dir/tf.sh" "$action" -input=false \
  -var "resource_pool_id=${resource_pool_id:-rhem-eap-demo}" \
  -var "vm_role=$role" \
  -var "vm_id=$vm_id" \
  -var "vm_name=$vm_name" \
  -var "dns_name=$dns_name" \
  -var "vm_description=$description" \
  -var "vm_cores=$cores" \
  -var "vm_memory_mb=$memory_mb" \
  -var "vm_disk_gb=$disk_gb" \
  -var "ipv4_use_dhcp=$([[ "$ipv4_mode" == "dhcp" ]] && echo true || echo false)" \
  -var "ipv4_cidr=$ipv4_cidr" \
  -var "ipv4_gateway=$ipv4_gateway" \
  -var "dns_servers=$dns_hcl" \
  -var "vm_tags=$tag_hcl")

if [[ "$action" == "apply" || "$action" == "destroy" ]]; then
  cmd+=("-auto-approve")
fi

"${cmd[@]}"
