variable "proxmox_endpoint" {
  type        = string
  description = "Proxmox API URL, e.g. https://192.168.4.100:8006/"
}

variable "proxmox_insecure" {
  type        = bool
  default     = true
  description = "Skip TLS verify (typical for lab with self-signed PVE cert)"
}

variable "proxmox_node" {
  type        = string
  description = "PVE node name (Datacenter → node, e.g. habitvillage). Read-only reference VMs on this node; Terraform does not modify them."
}

variable "vm_name" {
  type    = string
  default = "rhem-prereq-rhel-01"
}

variable "vm_id" {
  type        = number
  description = "Unique VM ID on the node (pick a free id)"
}

variable "vm_cores" {
  type        = number
  default     = 4
  description = "RHEM on RHEL recommends 4 cores"
}

variable "vm_memory_mb" {
  type        = number
  default     = 16384
  description = "RHEM on RHEL recommends 16 GB RAM"
}

variable "vm_disk_gb" {
  type        = number
  default     = 80
  description = "Guest image + containers; increase if needed"
}

variable "network_bridge" {
  type        = string
  default     = "vmbr0"
  description = "Same bridge as habitvillage nodes (e.g. net0 virtio,bridge=vmbr0)"
}

variable "disk_storage" {
  type        = string
  description = "VM disk pool — habitvillage uses local-zfs for scsi disks"
}

variable "disk_interface" {
  type        = string
  default     = "scsi0"
  description = "Disk bus; scsi0 + virtio-scsi matches k3s nodes"
}

variable "disk_iothread" {
  type        = bool
  default     = true
  description = "Match habitvillage-style iothread=1 on primary disk"
}

variable "disk_ssd" {
  type        = bool
  default     = true
  description = "SSD emulation flag like habitvillage scsi disks"
}

variable "cpu_type" {
  type        = string
  default     = "x86-64-v2-AES"
  description = "QEMU CPU model; habitvillage k3s nodes use x86-64-v2-AES"
}

variable "cloud_image_import_id" {
  type    = string
  default = "local:import/rhel9-guest-image.qcow2"
  description = "When cloud_image_download_url is empty: existing volid for the RHEL 9 KVM qcow2 (upload manually). Ignored when download URL is set."
}

variable "cloud_image_download_url" {
  type        = string
  default     = ""
  description = "If non-empty, Proxmox downloads this HTTPS URL into import storage before creating the VM (see proxmox_virtual_environment_download_file). RHEL portal links usually require auth — use an internal mirror or presigned URL, or leave empty and upload the image manually."
}

variable "cloud_image_import_datastore_id" {
  type        = string
  default     = "local"
  description = "Datastore that allows content type Import (often 'local' dir), not necessarily the same as disk_storage (e.g. local-zfs)"
}

variable "cloud_image_download_file_name" {
  type        = string
  default     = "rhel9-guest-image.qcow2"
  description = "Filename on the import datastore when using cloud_image_download_url"
}

variable "cloud_image_download_timeout_seconds" {
  type        = number
  default     = 3600
  description = "Proxmox download-url task timeout (large qcow2)"
}

variable "cloud_image_download_verify_tls" {
  type        = bool
  default     = true
  description = "Verify TLS for the download URL (set false only for lab mirrors with broken certs)"
}

variable "cloud_image_download_overwrite" {
  type        = bool
  default     = false
  description = "If true, replace import when upstream size changes; if false, skip checks (faster re-apply)"
}

variable "ci_user" {
  type        = string
  default     = "cloud-user"
  description = "RHEL generic cloud images use cloud-user"
}

variable "ssh_public_key" {
  type        = string
  description = "SSH public key for cloud-init (one line)"
}

variable "rhem_resource_pool_id" {
  type        = string
  default     = "rhem-eap-prereq"
  description = "Proxmox resource pool for this project only (not habitvillage pool)"
}

variable "vm_tags" {
  type        = list(string)
  default     = ["managed-by-terraform", "project-rhem-eap", "platform-proxmox", "os-rhel", "role-prereq"]
  description = "Proxmox tags (metadata only)"
}

variable "vm_description" {
  type        = string
  default     = "RHEL 9 cloud image — Terraform + cloud-init network — pool rhem-eap-prereq only"
  description = "VM notes in Proxmox UI"
}

# --- Cloud-init network (habitvillage reference: gw=192.168.4.1, /22, internal DNS + forwarders) ---

variable "ipv4_use_dhcp" {
  type        = bool
  default     = false
  description = "If true, use DHCP; if false, set ipv4_cidr + ipv4_gateway (habitvillage uses static ipconfig0)"
}

variable "ipv4_cidr" {
  type        = string
  default     = "192.168.4.240/22"
  description = "Static address in CIDR; host is on 192.168.4.100/22 — pick unused IP"
}

variable "ipv4_gateway" {
  type        = string
  default     = "192.168.4.1"
}

variable "dns_servers" {
  type        = list(string)
  default     = ["192.168.4.220", "1.1.1.1", "8.8.8.8"]
  description = "Matches habitvillage nameserver order (internal first, then forwarders)"
}

variable "dns_domain" {
  type        = string
  default     = "rhem-eap.lan"
  description = "Search domain (habitvillage uses habitvillage.lan; keep separate for this project)"
}
