#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/../.." && pwd)"
env_dir="$repo_root/automation/terraform/environments/device-vm"
metadata_dir="$env_dir/.device-metadata"

"$repo_root/automation/scripts/init-files.sh"

terraform -chdir="$env_dir" init -input=false >/dev/null

workspace_list="$(
  terraform -chdir="$env_dir" workspace list -no-color 2>/dev/null \
    | sed 's/^[* ]*//' \
    | awk 'NF'
)"

if [[ -z "$workspace_list" ]]; then
  echo "No device VM workspaces found."
  exit 0
fi

destroy_workspace() {
  local workspace_name="$1"

  terraform -chdir="$env_dir" workspace select "$workspace_name" >/dev/null

  echo "Destroying device VM workspace: $workspace_name"
  (
    cd "$env_dir"
    ./tf.sh destroy -auto-approve -input=false
  )

  rm -f "$metadata_dir/${workspace_name}.env"

  if [[ "$workspace_name" != "default" ]]; then
    terraform -chdir="$env_dir" workspace select default >/dev/null
    terraform -chdir="$env_dir" workspace delete "$workspace_name" >/dev/null || true
  fi
}

while IFS= read -r workspace_name; do
  [[ -n "$workspace_name" ]] || continue
  if [[ "$workspace_name" != "default" ]]; then
    destroy_workspace "$workspace_name"
  fi
done <<< "$workspace_list"

if printf '%s\n' "$workspace_list" | grep -Fxq "default"; then
  destroy_workspace "default"
fi

terraform -chdir="$env_dir" workspace select default >/dev/null
