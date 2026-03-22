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
device_name="${DEVICE_NAME:-}"
device_site="${DEVICE_SITE:-}"
device_label_kvs="${DEVICE_LABEL_KVS:-}"
device_metadata_dir="${env_dir}/.device-metadata"

slugify() {
  printf '%s' "$1" \
    | tr '[:upper:]' '[:lower:]' \
    | sed -E 's/[^a-z0-9]+/-/g; s/^-+//; s/-+$//; s/-{2,}/-/g'
}

read_tfvars_string() {
  local key="$1"
  python3 - "$env_dir/terraform.tfvars" "$key" <<'PY'
import pathlib
import re
import sys

path = pathlib.Path(sys.argv[1])
key = sys.argv[2]
pattern = re.compile(r'^\s*' + re.escape(key) + r'\s*=\s*"([^"]*)"')

if not path.exists():
    sys.exit(0)

for line in path.read_text(encoding="utf-8").splitlines():
    match = pattern.match(line)
    if match:
        print(match.group(1))
        break
PY
}

load_proxmox_env() {
  if [[ -f "$env_dir/.env" ]]; then
    set -a
    # shellcheck source=/dev/null
    source "$env_dir/.env"
    set +a
  fi
}

get_workspace_name() {
  if [[ -n "$device_name" ]]; then
    local device_slug
    device_slug="$(slugify "$device_name")"
    printf 'device-%s' "$device_slug"
  else
    printf 'default'
  fi
}

workspace_exists() {
  local workspace_name="$1"
  terraform -chdir="$env_dir" workspace list -no-color | sed 's/^[* ]*//' | grep -Fxq "$workspace_name"
}

select_workspace() {
  local workspace_name="$1"

  if workspace_exists "$workspace_name"; then
    terraform -chdir="$env_dir" workspace select "$workspace_name" >/dev/null
    return
  fi

  if [[ "$action" == "destroy" ]]; then
    echo "Terraform workspace '$workspace_name' does not exist. Pass the same name= value you used for make device-vm-up." >&2
    exit 1
  fi

  terraform -chdir="$env_dir" workspace new "$workspace_name" >/dev/null
}

read_workspace_output() {
  local output_name="$1"
  terraform -chdir="$env_dir" output -raw "$output_name" 2>/dev/null || true
}

detect_next_vm_id() {
  load_proxmox_env

  local endpoint="${PROXMOX_ENDPOINT:-}"
  local insecure="${PROXMOX_VE_INSECURE:-true}"
  local curl_args=(-fsS)
  local auth_response nextid_response

  if [[ "$insecure" == "true" ]]; then
    curl_args+=(-k)
  fi

  if [[ -z "$endpoint" ]]; then
    endpoint="$(read_tfvars_string proxmox_endpoint)"
  fi

  if [[ -z "$endpoint" ]]; then
    echo "Could not determine proxmox_endpoint for automatic VM ID allocation." >&2
    exit 1
  fi

  endpoint="${endpoint%/}"

  if [[ -n "${PROXMOX_VE_API_TOKEN:-}" ]]; then
    nextid_response="$(curl "${curl_args[@]}" \
      -H "Authorization: PVEAPIToken=${PROXMOX_VE_API_TOKEN}" \
      "$endpoint/api2/json/cluster/nextid")"
  elif [[ -n "${PROXMOX_VE_USERNAME:-}" && -n "${PROXMOX_VE_PASSWORD:-}" ]]; then
    auth_response="$(curl "${curl_args[@]}" \
      --data-urlencode "username=${PROXMOX_VE_USERNAME}" \
      --data-urlencode "password=${PROXMOX_VE_PASSWORD}" \
      "$endpoint/api2/json/access/ticket")"

    local ticket
    ticket="$(python3 - "$auth_response" <<'PY'
import json
import sys

payload = json.loads(sys.argv[1])
print(payload.get("data", {}).get("ticket", ""))
PY
)"

    if [[ -z "$ticket" ]]; then
      echo "Failed to obtain a Proxmox API ticket for automatic VM ID allocation." >&2
      exit 1
    fi

    nextid_response="$(curl "${curl_args[@]}" \
      -H "Cookie: PVEAuthCookie=${ticket}" \
      "$endpoint/api2/json/cluster/nextid")"
  else
    echo "Proxmox credentials are required for automatic VM ID allocation." >&2
    exit 1
  fi

  python3 - "$nextid_response" <<'PY'
import json
import sys

payload = json.loads(sys.argv[1])
value = payload.get("data", "")
if value == "":
    sys.exit(1)
print(value)
PY
}

build_vm_tags_hcl() {
  local device_slug tag_hcl
  local -a tag_items extra_tag_array

  tag_items=("device-demo")

  if [[ -n "$device_name" ]]; then
    device_slug="$(slugify "$device_name")"
    tag_items+=("device-${device_slug}")
  fi

  if [[ -n "$vm_tags" ]]; then
    IFS=',' read -r -a extra_tag_array <<< "$vm_tags"
    for tag in "${extra_tag_array[@]}"; do
      [[ -n "$tag" ]] || continue
      tag_items+=("$tag")
    done
  fi

  tag_hcl="["
  local seen=","
  for tag in "${tag_items[@]}"; do
    [[ -n "$tag" ]] || continue
    if [[ "$seen" == *",$tag,"* ]]; then
      continue
    fi
    if [[ "$tag_hcl" != "[" ]]; then
      tag_hcl+=", "
    fi
    tag_hcl+="\"$tag\""
    seen+="$tag,"
  done
  tag_hcl+="]"

  printf '%s' "$tag_hcl"
}

build_device_label_kvs_csv() {
  local item key value key_slug value_slug csv=""
  local -a label_items extra_label_kv_array

  if [[ -n "$device_site" ]]; then
    label_items+=("site=$device_site")
  fi

  if [[ -n "$device_label_kvs" ]]; then
    IFS=' ' read -r -a extra_label_kv_array <<< "$device_label_kvs"
    for item in "${extra_label_kv_array[@]}"; do
      [[ -n "$item" && "$item" == *=* ]] || continue
      key="${item%%=*}"
      value="${item#*=}"
      [[ -n "$key" && -n "$value" ]] || continue
      key_slug="$(slugify "$key")"
      value_slug="$(slugify "$value")"
      [[ -n "$key_slug" && -n "$value_slug" ]] || continue
      label_items+=("${key_slug}=${value_slug}")
    done
  fi

  local seen=","
  for item in "${label_items[@]}"; do
    [[ -n "$item" ]] || continue
    if [[ "$seen" == *",$item,"* ]]; then
      continue
    fi
    if [[ -n "$csv" ]]; then
      csv+=","
    fi
    csv+="$item"
    seen+="$item,"
  done

  printf '%s' "$csv"
}

device_metadata_path() {
  local workspace_name="$1"
  printf '%s/%s.env' "$device_metadata_dir" "$workspace_name"
}

persist_device_metadata() {
  local workspace_name="$1"
  local metadata_path label_kvs_csv

  [[ -n "$device_name" ]] || return 0

  metadata_path="$(device_metadata_path "$workspace_name")"
  label_kvs_csv="$(build_device_label_kvs_csv)"

  mkdir -p "$device_metadata_dir"
  cat > "$metadata_path" <<EOF
DEVICE_NAME=$(printf '%q' "$device_name")
DEVICE_SITE=$(printf '%q' "$device_site")
DEVICE_LABEL_KVS_CSV=$(printf '%q' "$label_kvs_csv")
EOF
}

remove_device_metadata() {
  local workspace_name="$1"
  rm -f "$(device_metadata_path "$workspace_name")"
}

if [[ -z "$bootc_qcow2_path" ]]; then
  bootc_qcow2_path="$(find "$repo_root/automation/artifacts/bootc" -maxdepth 3 -type f -name 'disk.qcow2' | sort | tail -n 1)"
fi

if [[ -z "$bootc_qcow2_path" && "$action" == "destroy" ]]; then
  bootc_qcow2_path="$(read_tfvars_string bootc_qcow2_path)"
fi

if [[ "$action" != "destroy" && ( -z "$bootc_qcow2_path" || ! -f "$bootc_qcow2_path" ) ]]; then
  echo "No bootc qcow2 artifact was found. Run 'BOOTC_BUILD_QCOW2=true BOOTC_FETCH_QCOW2=true make bootc-build' first, or set BOOTC_QCOW2_PATH." >&2
  exit 1
fi

if [[ -z "$bootc_qcow2_path" ]]; then
  bootc_qcow2_path="/tmp/rhem-device-placeholder.qcow2"
fi

terraform -chdir="$env_dir" init -input=false >/dev/null

workspace_name="$(get_workspace_name)"
select_workspace "$workspace_name"

if [[ -z "$vm_id" ]]; then
  vm_id="$(read_workspace_output vm_id)"
fi

if [[ -z "$vm_id" && "$action" != "destroy" ]]; then
  vm_id="$(detect_next_vm_id)"
fi

if [[ -z "$vm_id" ]]; then
  echo "VM_ID is required for destroy when the device workspace has no saved output. Pass VM_ID explicitly if needed." >&2
  exit 1
fi

if [[ -z "$vm_name" && -n "$device_name" ]]; then
  vm_name="rhem-device-$(slugify "$device_name")"
fi

if [[ -z "$uploaded_qcow2_file_name" && -n "$device_name" ]]; then
  uploaded_qcow2_file_name="rhem-demo-device-$(slugify "$device_name").qcow2"
fi

if [[ -z "$vm_description" && -n "$device_name" && -n "$device_site" ]]; then
  vm_description="Red Hat Edge Manager demo device (${device_name}, site ${device_site})"
elif [[ -z "$vm_description" && -n "$device_name" ]]; then
  vm_description="Red Hat Edge Manager demo device (${device_name})"
fi

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

if [[ -n "$device_name" || -n "$device_site" || -n "$vm_tags" ]]; then
  cmd+=(-var "vm_tags=$(build_vm_tags_hcl)")
fi

if [[ "$action" == "apply" || "$action" == "destroy" ]]; then
  cmd+=(-auto-approve)
fi

echo "Using device workspace: $workspace_name" >&2
if [[ -n "$device_name" ]]; then
  echo "Device name: $device_name" >&2
fi
if [[ -n "$device_site" ]]; then
  echo "Device site: $device_site" >&2
fi
echo "VM ID: $vm_id" >&2

"${cmd[@]}"

if [[ "$action" == "apply" ]]; then
  persist_device_metadata "$workspace_name"
elif [[ "$action" == "destroy" ]]; then
  remove_device_metadata "$workspace_name"
fi
