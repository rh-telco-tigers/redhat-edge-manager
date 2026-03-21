variable "proxmox_node" {
  type        = string
  description = "PVE node name"
}

variable "pool_id" {
  type        = string
  default     = ""
  description = "Optional Proxmox resource pool ID"
}

variable "vm_role" {
  type        = string
  description = "Logical role for tagging and defaults"
}

variable "vm_name" {
  type        = string
  description = "Proxmox VM name"
}

variable "fqdn" {
  type        = string
  description = "Expected DNS name for this host"
}

variable "vm_description" {
  type        = string
  description = "VM notes in Proxmox UI"
}

variable "vm_id" {
  type        = number
  description = "Unique VM ID on the Proxmox node"
}

variable "vm_cores" {
  type        = number
  description = "Virtual CPU cores"
}

variable "vm_memory_mb" {
  type        = number
  description = "Dedicated memory in MB"
}

variable "vm_disk_gb" {
  type        = number
  description = "Primary disk size in GB"
}

variable "network_bridge" {
  type        = string
  description = "Bridge name, for example vmbr0"
}

variable "disk_storage" {
  type        = string
  description = "Datastore for the primary VM disk"
}

variable "disk_interface" {
  type        = string
  default     = "scsi0"
  description = "Primary disk bus"
}

variable "disk_iothread" {
  type        = bool
  default     = true
  description = "Enable iothread on the primary disk"
}

variable "disk_ssd" {
  type        = bool
  default     = true
  description = "Enable SSD emulation"
}

variable "cpu_type" {
  type        = string
  default     = "x86-64-v2-AES"
  description = "QEMU CPU type"
}

variable "cloud_image_import_id" {
  type        = string
  default     = "local:import/rhel9-guest-image.qcow2"
  description = "Existing Proxmox volume ID for the RHEL qcow2"
}

variable "cloud_image_download_url" {
  type        = string
  default     = ""
  description = "Optional HTTPS URL that Proxmox can fetch server-side"
}

variable "cloud_image_import_datastore_id" {
  type        = string
  default     = "local"
  description = "Datastore that allows content type Import"
}

variable "cloud_image_download_file_name" {
  type        = string
  default     = "rhel9-guest-image.qcow2"
  description = "Filename on the import datastore when download URL is used"
}

variable "cloud_image_download_timeout_seconds" {
  type        = number
  default     = 3600
  description = "Timeout for server-side image download"
}

variable "cloud_image_download_verify_tls" {
  type        = bool
  default     = true
  description = "Verify TLS for the image download URL"
}

variable "cloud_image_download_overwrite" {
  type        = bool
  default     = false
  description = "Overwrite an existing downloaded import file"
}

variable "ci_user" {
  type        = string
  default     = "cloud-user"
  description = "Cloud-init username"
}

variable "ssh_public_key" {
  type        = string
  description = "SSH public key injected by cloud-init"
}

variable "extra_tags" {
  type        = list(string)
  default     = []
  description = "Additional Proxmox tags"
}

variable "ipv4_use_dhcp" {
  type        = bool
  default     = false
  description = "Use DHCP instead of a static address"
}

variable "ipv4_cidr" {
  type        = string
  default     = ""
  description = "Static IPv4 address in CIDR format"
}

variable "ipv4_gateway" {
  type        = string
  default     = ""
  description = "Gateway for the static IPv4 address"
}

variable "dns_servers" {
  type        = list(string)
  default     = []
  description = "DNS servers written through cloud-init"
}

variable "dns_domain" {
  type        = string
  description = "DNS search domain"
}

variable "stop_on_destroy" {
  type        = bool
  default     = true
  description = "Gracefully stop the VM before destroy"
}
