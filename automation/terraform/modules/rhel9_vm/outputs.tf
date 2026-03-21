output "vm_id" {
  value       = proxmox_virtual_environment_vm.this.vm_id
  description = "Assigned Proxmox VM ID"
}

output "vm_name" {
  value       = proxmox_virtual_environment_vm.this.name
  description = "VM name shown in Proxmox"
}

output "ipv4_addresses" {
  value       = proxmox_virtual_environment_vm.this.ipv4_addresses
  description = "IPv4 addresses reported by the guest agent"
}

output "cloud_disk_import_from" {
  value       = local.cloud_disk_import_from
  description = "Volume ID used for disk import"
}

output "fqdn" {
  value       = var.fqdn
  description = "Expected DNS name for this host"
}
