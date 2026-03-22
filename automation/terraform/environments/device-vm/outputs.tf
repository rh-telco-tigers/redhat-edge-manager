output "vm_id" {
  value       = proxmox_virtual_environment_vm.device.vm_id
  description = "Assigned Proxmox VM ID"
}

output "vm_name" {
  value       = proxmox_virtual_environment_vm.device.name
  description = "VM name in Proxmox"
}

output "bootc_iso_file_id" {
  value       = proxmox_virtual_environment_file.bootc_iso.id
  description = "Uploaded bootc ISO file ID"
}
