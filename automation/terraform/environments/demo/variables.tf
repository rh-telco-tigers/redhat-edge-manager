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
  description = "Dedicated Proxmox resource pool for the demo"
}

variable "network_bridge" {
  type        = string
  default     = "vmbr0"
  description = "Bridge for all VMs"
}

variable "disk_storage" {
  type        = string
  description = "Datastore for primary VM disks"
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
  description = "Existing Proxmox volume ID for the shared RHEL guest image"
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
  description = "SSH public key injected into every VM"
}

variable "ssh_public_key_path" {
  type        = string
  default     = ""
  description = "Path to a local SSH public key file on the machine running Terraform"
}

variable "ssh_private_key_path" {
  type        = string
  default     = ""
  description = "Optional path to the matching local SSH private key for Ansible access"
}

variable "dns_domain" {
  type        = string
  default     = "rhem-eap.lan"
  description = "DNS search domain for the demo"
}

variable "default_ipv4_gateway" {
  type        = string
  default     = "192.168.4.1"
  description = "Default IPv4 gateway for static hosts"
}

variable "upstream_dns_servers" {
  type        = list(string)
  default     = ["1.1.1.1", "8.8.8.8"]
  description = "Fallback DNS servers written alongside the internal PDNS host"
}

variable "generate_ansible_inventory" {
  type        = bool
  default     = true
  description = "Write a generated inventory file for the automation playbooks"
}

variable "ansible_inventory_output_path" {
  type        = string
  default     = "../../../ansible/inventory/hosts.generated.yml"
  description = "Relative path for the generated Ansible inventory"
}

variable "vms" {
  type = map(object({
    enabled        = bool
    role           = string
    vm_id          = number
    vm_name        = string
    vm_description = string
    vm_cores       = number
    vm_memory_mb   = number
    vm_disk_gb     = number
    dns_name       = string
    ipv4_use_dhcp  = bool
    ipv4_cidr      = string
    ipv4_gateway   = string
    groups         = list(string)
    extra_tags     = list(string)
  }))
  description = "Logical VM inventory for the full demo stack"
}
