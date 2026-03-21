variable "proxmox_endpoint" {
  type        = string
  description = "Proxmox API URL, e.g. https://192.168.4.101:8006/"
}

variable "proxmox_insecure" {
  type        = bool
  default     = true
  description = "Skip TLS verify for lab Proxmox"
}

variable "proxmox_node" {
  type        = string
  description = "PVE node name"
}

variable "vm_name" {
  type    = string
  default = "rhem-keycloak-01"
}

variable "vm_id" {
  type        = number
  description = "Unique VM ID on the node"
}

variable "resource_pool_id" {
  type        = string
  default     = "rhem-eap-prereq"
  description = "Reuse the same project pool unless you want a dedicated one"
}

variable "vm_cores" {
  type    = number
  default = 2
}

variable "vm_memory_mb" {
  type    = number
  default = 4096
}

variable "vm_disk_gb" {
  type    = number
  default = 40
}

variable "network_bridge" {
  type    = string
  default = "vmbr0"
}

variable "disk_storage" {
  type        = string
  description = "VM disk datastore"
}

variable "disk_interface" {
  type    = string
  default = "scsi0"
}

variable "disk_iothread" {
  type    = bool
  default = true
}

variable "disk_ssd" {
  type    = bool
  default = true
}

variable "cpu_type" {
  type    = string
  default = "x86-64-v2-AES"
}

variable "cloud_image_import_id" {
  type    = string
  default = "local:import/rhel9-guest-image.qcow2"
}

variable "cloud_image_download_url" {
  type    = string
  default = ""
}

variable "cloud_image_import_datastore_id" {
  type    = string
  default = "local"
}

variable "cloud_image_download_file_name" {
  type    = string
  default = "rhel9-guest-image.qcow2"
}

variable "cloud_image_download_timeout_seconds" {
  type    = number
  default = 3600
}

variable "cloud_image_download_verify_tls" {
  type    = bool
  default = true
}

variable "cloud_image_download_overwrite" {
  type    = bool
  default = false
}

variable "ci_user" {
  type    = string
  default = "cloud-user"
}

variable "ssh_public_key" {
  type        = string
  description = "SSH public key for cloud-init"
}

variable "vm_tags" {
  type        = list(string)
  default     = ["managed-by-terraform", "project-rhem-eap", "platform-proxmox", "os-rhel", "role-keycloak"]
  description = "Proxmox tags"
}

variable "vm_description" {
  type        = string
  default     = "RHEL 9 cloud image for Keycloak — Terraform + cloud-init network"
  description = "VM notes in Proxmox UI"
}

variable "ipv4_use_dhcp" {
  type    = bool
  default = true
}

variable "ipv4_cidr" {
  type    = string
  default = "192.168.4.241/22"
}

variable "ipv4_gateway" {
  type    = string
  default = "192.168.4.1"
}

variable "dns_servers" {
  type    = list(string)
  default = ["192.168.4.220", "1.1.1.1", "8.8.8.8"]
}

variable "dns_domain" {
  type    = string
  default = "rhem-eap.lan"
}
