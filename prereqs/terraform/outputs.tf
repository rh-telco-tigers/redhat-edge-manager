output "vm_id" {
  value       = proxmox_virtual_environment_vm.prereq.vm_id
  description = "Assigned Proxmox VM ID"
}

output "vm_name" {
  value = proxmox_virtual_environment_vm.prereq.name
}

output "resource_pool_id" {
  value       = proxmox_virtual_environment_pool.rhem_prereq.pool_id
  description = "Proxmox pool containing this VM (not habitvillage)"
}

output "notes" {
  value       = "Get IP from Proxmox UI (Summary → Network) or DHCP leases; QEMU guest agent helps after boot."
  description = "Where to find the VM address"
}

output "cloud_disk_import_from" {
  value       = local.cloud_disk_import_from
  description = "Volid used for disk import (download_file.id if URL set, else cloud_image_import_id)"
}
