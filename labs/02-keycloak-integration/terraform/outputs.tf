output "vm_id" {
  value       = proxmox_virtual_environment_vm.keycloak.vm_id
  description = "Assigned Proxmox VM ID"
}

output "vm_name" {
  value = proxmox_virtual_environment_vm.keycloak.name
}

output "vm_ipv4_addresses" {
  value       = proxmox_virtual_environment_vm.keycloak.ipv4_addresses
  description = "IPv4 addresses reported by the guest agent"
}

output "cloud_disk_import_from" {
  value       = local.cloud_disk_import_from
  description = "Volid used for disk import"
}

output "notes" {
  value       = "After apply, use the guest agent IP for the Ansible inventory and run the automation in ../ansible."
  description = "Next step after VM creation"
}
