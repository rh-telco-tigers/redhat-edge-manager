#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/../.." && pwd)"

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

copy_if_missing \
  "$repo_root/automation/terraform/environments/demo/.env" \
  "$repo_root/prereqs/terraform/.env" \
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
  "$repo_root/automation/terraform/environments/single-rhel9/terraform.tfvars" \
  "" \
  "$repo_root/automation/terraform/environments/single-rhel9/terraform.tfvars.example"

copy_if_missing \
  "$repo_root/automation/ansible/group_vars/all.yml" \
  "$repo_root/labs/02-keycloak-integration/ansible/group_vars/all.yml" \
  "$repo_root/automation/ansible/group_vars/all.yml.example"

if [[ ! -f "$repo_root/automation/ansible/inventory/hosts.generated.yml" && -f "$repo_root/labs/02-keycloak-integration/ansible/inventory/hosts.yml" ]]; then
  cp "$repo_root/labs/02-keycloak-integration/ansible/inventory/hosts.yml" \
    "$repo_root/automation/ansible/inventory/hosts.generated.yml"
fi
