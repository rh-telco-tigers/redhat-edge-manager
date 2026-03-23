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

variable "proxmox_ssh_username" {
  type        = string
  default     = "root"
  description = "SSH username for Proxmox node access used during snippet uploads"
}

variable "proxmox_ssh_host" {
  type        = string
  default     = ""
  description = "Optional SSH hostname for the Proxmox node; defaults to the API endpoint host"
}

variable "proxmox_ssh_port" {
  type        = number
  default     = 22
  description = "SSH port for the Proxmox node"
}

variable "resource_pool_id" {
  type        = string
  default     = "rhem-eap-demo"
  description = "Dedicated Proxmox resource pool for automation-managed VMs"
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

variable "import_datastore_id" {
  type        = string
  default     = "local"
  description = "Datastore that supports imported qcow2 content"
}

variable "cloud_init_datastore_id" {
  type        = string
  default     = "local"
  description = "Datastore that supports snippets content for cloud-init user-data"
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

variable "vm_bios" {
  type        = string
  default     = "ovmf"
  description = "Firmware for the bootc device VM"
}

variable "vm_machine" {
  type        = string
  default     = "q35"
  description = "QEMU machine type for the bootc device VM"
}

variable "efi_disk_type" {
  type        = string
  default     = "4m"
  description = "EFI vars disk type for OVMF"
}

variable "bootc_qcow2_path" {
  type        = string
  description = "Local path to the bootc qcow2 artifact"
}

variable "uploaded_qcow2_file_name" {
  type        = string
  default     = "rhem-demo-device.qcow2"
  description = "Filename to use on the Proxmox import datastore"
}

variable "cloud_init_user_data_path" {
  type        = string
  default     = ""
  description = "Optional local path to a cloud-init user-data file"
}

variable "cloud_init_file_name" {
  type        = string
  default     = "rhem-demo-device-user-data.yaml"
  description = "Filename to use for the uploaded cloud-init user-data snippet"
}

variable "timeout_upload" {
  type        = number
  default     = 7200
  description = "Timeout for installer ISO upload"
}

variable "vm_id" {
  type        = number
  description = "Unique VM ID on the Proxmox node"
}

variable "vm_name" {
  type        = string
  default     = "rhem-device-01"
  description = "Proxmox VM name"
}

variable "vm_description" {
  type        = string
  default     = "Red Hat Edge Manager demo device"
  description = "VM notes in Proxmox UI"
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
  default     = 20
  description = "Primary disk size in GB"
}

variable "vm_tags" {
  type        = list(string)
  default     = []
  description = "Additional Proxmox tags"
}
