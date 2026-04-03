variable "proxmox_endpoint" {
  type        = string
  description = "Proxmox API URL"
}

variable "proxmox_node" {
  type        = string
  description = "Proxmox node name"
}

variable "disk_storage" {
  type        = string
  description = "Datastore for the VM disks"
}

variable "bootc_qcow2_path" {
  type        = string
  description = "Local path to the built bootc qcow2 image"
}

variable "cloud_init_user_data_path" {
  type        = string
  default     = ""
  description = "Optional local path to a cloud-init user-data file for late binding"
}

variable "vm_id" {
  type        = number
  description = "Unique VM ID on the Proxmox node"
}

variable "vm_name" {
  type        = string
  description = "VM name"
}
