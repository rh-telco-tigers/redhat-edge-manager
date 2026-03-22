#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/../.." && pwd)"
env_dir="$repo_root/automation/terraform/environments/device-vm"

"$repo_root/automation/scripts/init-files.sh"

action="${ACTION:-apply}"
bootc_qcow2_path="${BOOTC_QCOW2_PATH:-}"
uploaded_qcow2_file_name="${UPLOADED_QCOW2_FILE_NAME:-}"
vm_id="${VM_ID:-}"
vm_name="${VM_NAME:-}"
vm_description="${VM_DESCRIPTION:-}"
vm_cores="${VM_CORES:-}"
vm_memory_mb="${VM_MEMORY_MB:-}"
vm_disk_gb="${VM_DISK_GB:-}"
vm_tags="${VM_TAGS:-}"

if [[ -z "$bootc_qcow2_path" ]]; then
  bootc_qcow2_path="$(find "$repo_root/automation/artifacts/bootc" -maxdepth 3 -type f -name 'disk.qcow2' | sort | tail -n 1)"
fi

if [[ -z "$bootc_qcow2_path" || ! -f "$bootc_qcow2_path" ]]; then
  echo "No bootc qcow2 artifact was found. Run 'BOOTC_BUILD_QCOW2=true BOOTC_FETCH_QCOW2=true make bootc-build' first, or set BOOTC_QCOW2_PATH." >&2
  exit 1
fi

terraform -chdir="$env_dir" init -input=false >/dev/null

cmd=("$env_dir/tf.sh" "$action" -input=false -var "bootc_qcow2_path=$bootc_qcow2_path")

if [[ -n "$uploaded_qcow2_file_name" ]]; then
  cmd+=(-var "uploaded_qcow2_file_name=$uploaded_qcow2_file_name")
fi

if [[ -n "$vm_id" ]]; then
  cmd+=(-var "vm_id=$vm_id")
fi

if [[ -n "$vm_name" ]]; then
  cmd+=(-var "vm_name=$vm_name")
fi

if [[ -n "$vm_description" ]]; then
  cmd+=(-var "vm_description=$vm_description")
fi

if [[ -n "$vm_cores" ]]; then
  cmd+=(-var "vm_cores=$vm_cores")
fi

if [[ -n "$vm_memory_mb" ]]; then
  cmd+=(-var "vm_memory_mb=$vm_memory_mb")
fi

if [[ -n "$vm_disk_gb" ]]; then
  cmd+=(-var "vm_disk_gb=$vm_disk_gb")
fi

if [[ -n "$vm_tags" ]]; then
  tag_hcl="["
  IFS=',' read -r -a tag_array <<< "$vm_tags"
  for tag in "${tag_array[@]}"; do
    [[ -n "$tag" ]] || continue
    if [[ "$tag_hcl" != "[" ]]; then
      tag_hcl+=", "
    fi
    tag_hcl+="\"$tag\""
  done
  tag_hcl+="]"
  cmd+=(-var "vm_tags=$tag_hcl")
fi

if [[ "$action" == "apply" || "$action" == "destroy" ]]; then
  cmd+=(-auto-approve)
fi

"${cmd[@]}"
