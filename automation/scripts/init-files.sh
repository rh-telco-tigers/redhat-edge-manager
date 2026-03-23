#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/../.." && pwd)"
demo_ssh_key_path="${HOME}/.ssh/redhat-edge-manager-demo"

copy_if_missing() {
  local destination="$1"
  local source_primary="$2"
  local source_fallback="$3"

  if [[ -f "$destination" ]]; then
    return 0
  fi

  if [[ -n "$source_primary" && -f "$source_primary" ]]; then
    cp "$source_primary" "$destination"
    return 0
  fi

  cp "$source_fallback" "$destination"
}

ensure_demo_ssh_key() {
  mkdir -p "${HOME}/.ssh"
  chmod 700 "${HOME}/.ssh"

  if [[ ! -f "$demo_ssh_key_path" ]]; then
    ssh-keygen -t ed25519 -f "$demo_ssh_key_path" -N "" -C "redhat-edge-manager-demo" >/dev/null
  fi

  chmod 600 "$demo_ssh_key_path"
  chmod 644 "${demo_ssh_key_path}.pub"
}

migrate_placeholder_ssh_key() {
  local tfvars_file="$1"

  [[ -f "$tfvars_file" ]] || return 0

  if grep -q 'ssh_public_key = "ssh-ed25519 AAAA... your-key-here"' "$tfvars_file"; then
    perl -0pi -e 's/ssh_public_key = "ssh-ed25519 AAAA\.\.\. your-key-here"/ssh_public_key_path = "~\/.ssh\/redhat-edge-manager-demo.pub"/g' "$tfvars_file"
  fi
}

migrate_device_vm_tfvars() {
  local tfvars_file="$1"

  [[ -f "$tfvars_file" ]] || return 0

  perl -0pi -e 's/^bootc_install_iso_path\s*=.*$/bootc_qcow2_path = "..\/..\/..\/artifacts\/bootc\/current\/rhem\/disk.qcow2"/mg' "$tfvars_file"
  perl -0pi -e 's/^bootc_qcow2_path\s*=.*$/bootc_qcow2_path = "..\/..\/..\/artifacts\/bootc\/current\/rhem\/disk.qcow2"/mg' "$tfvars_file"
  perl -0pi -e 's/^uploaded_iso_file_name\s*=.*$/uploaded_qcow2_file_name = "rhem-demo-device.qcow2"/mg' "$tfvars_file"
}

ensure_demo_ssh_key

copy_if_missing \
  "$repo_root/automation/terraform/environments/demo/.env" \
  "" \
  "$repo_root/automation/terraform/environments/demo/.env.example"

copy_if_missing \
  "$repo_root/automation/terraform/environments/demo/terraform.tfvars" \
  "" \
  "$repo_root/automation/terraform/environments/demo/terraform.tfvars.example"

copy_if_missing \
  "$repo_root/automation/terraform/environments/single-rhel9/.env" \
  "$repo_root/automation/terraform/environments/demo/.env" \
  "$repo_root/automation/terraform/environments/single-rhel9/.env.example"

copy_if_missing \
  "$repo_root/automation/terraform/environments/device-vm/.env" \
  "$repo_root/automation/terraform/environments/demo/.env" \
  "$repo_root/automation/terraform/environments/device-vm/.env.example"

copy_if_missing \
  "$repo_root/automation/terraform/environments/manual-demo/.env" \
  "$repo_root/automation/terraform/environments/demo/.env" \
  "$repo_root/automation/terraform/environments/manual-demo/.env.example"

copy_if_missing \
  "$repo_root/automation/terraform/environments/single-rhel9/terraform.tfvars" \
  "" \
  "$repo_root/automation/terraform/environments/single-rhel9/terraform.tfvars.example"

copy_if_missing \
  "$repo_root/automation/terraform/environments/manual-demo/terraform.tfvars" \
  "" \
  "$repo_root/automation/terraform/environments/manual-demo/terraform.tfvars.example"

copy_if_missing \
  "$repo_root/automation/terraform/environments/device-vm/terraform.tfvars" \
  "" \
  "$repo_root/automation/terraform/environments/device-vm/terraform.tfvars.example"

copy_if_missing \
  "$repo_root/automation/ansible/group_vars/all.yml" \
  "" \
  "$repo_root/automation/ansible/group_vars/all.yml.example"

migrate_placeholder_ssh_key "$repo_root/automation/terraform/environments/demo/terraform.tfvars"
migrate_placeholder_ssh_key "$repo_root/automation/terraform/environments/single-rhel9/terraform.tfvars"
migrate_placeholder_ssh_key "$repo_root/automation/terraform/environments/manual-demo/terraform.tfvars"
migrate_placeholder_ssh_key "$repo_root/automation/terraform/environments/device-vm/terraform.tfvars"
migrate_device_vm_tfvars "$repo_root/automation/terraform/environments/device-vm/terraform.tfvars"
