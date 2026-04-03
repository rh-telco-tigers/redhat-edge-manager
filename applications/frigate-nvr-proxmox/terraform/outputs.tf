output "vm_name" {
  value       = proxmox_virtual_environment_vm.device.name
  description = "Created VM name"
}

output "vm_id" {
  value       = proxmox_virtual_environment_vm.device.vm_id
  description = "Created VM ID"
}

output "ipv4_addresses" {
  value       = proxmox_virtual_environment_vm.device.ipv4_addresses
  description = "Guest-reported IPv4 addresses"
}
