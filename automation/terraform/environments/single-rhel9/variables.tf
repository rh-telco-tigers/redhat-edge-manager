variable "proxmox_endpoint" {
  type        = string
  description = "Proxmox API URL"
}

variable "proxmox_insecure" {
  type        = bool
  default     = true
  description = "Skip TLS verification for Proxmox"
}

variable "proxmox_node" {
  type        = string
  description = "PVE node name"
}

variable "resource_pool_id" {
  type        = string
  default     = "rhem-eap-demo"
  description = "Dedicated Proxmox resource pool for automation-managed VMs"
}

variable "vm_role" {
  type        = string
  default     = "generic"
  description = "Logical role for the VM"
}

variable "vm_name" {
  type        = string
  default     = "rhel9-generic-01"
  description = "Proxmox VM name"
}

variable "dns_name" {
  type        = string
  default     = "rhel9-generic-01"
  description = "Short DNS name used to form the FQDN"
}

variable "vm_description" {
  type        = string
  default     = "Generic RHEL 9 cloud image VM"
  description = "VM notes in Proxmox UI"
}

variable "vm_id" {
  type        = number
  description = "Unique VM ID on the Proxmox node"
}

variable "vm_cores" {
  type        = number
  default     = 2
  description = "Virtual CPU cores"
}

variable "vm_memory_mb" {
  type        = number
  default     = 4096
  description = "Dedicated memory in MB"
}

variable "vm_disk_gb" {
  type        = number
  default     = 40
  description = "Primary disk size in GB"
}

variable "network_bridge" {
  type        = string
  default     = "vmbr0"
  description = "Bridge for the VM NIC"
}

variable "disk_storage" {
  type        = string
  description = "Datastore for the primary VM disk"
}

variable "disk_interface" {
  type        = string
  default     = "scsi0"
  description = "Disk bus"
}

variable "disk_iothread" {
  type        = bool
  default     = true
  description = "Enable disk iothread"
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
  description = "Optional HTTPS URL for Proxmox to fetch the RHEL image"
}

variable "cloud_image_import_datastore_id" {
  type        = string
  default     = "local"
  description = "Datastore that supports import content"
}

variable "cloud_image_download_file_name" {
  type        = string
  default     = "rhel9-guest-image.qcow2"
  description = "Filename to use on the import datastore"
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
  description = "Overwrite an existing imported image"
}

variable "ci_user" {
  type        = string
  default     = "cloud-user"
  description = "Cloud-init username"
}

variable "ssh_public_key" {
  type        = string
  default     = ""
  description = "SSH public key injected by cloud-init"
}

variable "ssh_public_key_path" {
  type        = string
  default     = ""
  description = "Path to a local SSH public key file on the machine running Terraform"
}

variable "vm_tags" {
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
  default     = "192.168.4.1"
  description = "Gateway for the static IPv4 address"
}

variable "dns_servers" {
  type        = list(string)
  default     = ["1.1.1.1", "8.8.8.8"]
  description = "DNS servers written by cloud-init"
}

variable "dns_domain" {
  type        = string
  default     = "rhem-eap.lan"
  description = "DNS search domain"
}
