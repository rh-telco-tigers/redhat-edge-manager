output "vm_id" {
  value       = module.vm.vm_id
  description = "Assigned Proxmox VM ID"
}

output "vm_name" {
  value       = module.vm.vm_name
  description = "VM name in Proxmox"
}

output "vm_ipv4_addresses" {
  value       = module.vm.ipv4_addresses
  description = "IPv4 addresses reported by the guest agent"
}

output "vm_fqdn" {
  value       = module.vm.fqdn
  description = "Expected DNS name"
}

output "cloud_disk_import_from" {
  value       = module.vm.cloud_disk_import_from
  description = "Volume ID used for disk import"
}
