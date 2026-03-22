provider "proxmox" {
  endpoint = var.proxmox_endpoint
  insecure = var.proxmox_insecure
}

locals {
  vm_tags = distinct(concat([
    "managed-by-terraform",
    "project-rhem-eap",
    "platform-proxmox",
    "os-bootc",
    "role-device",
  ], var.vm_tags))
}

resource "proxmox_virtual_environment_file" "bootc_iso" {
  content_type   = "iso"
  datastore_id   = var.import_datastore_id
  node_name      = var.proxmox_node
  overwrite      = true
  timeout_upload = var.timeout_upload

  source_file {
    path      = abspath(pathexpand(var.bootc_install_iso_path))
    file_name = var.uploaded_iso_file_name
  }
}

resource "proxmox_virtual_environment_vm" "device" {
  name        = var.vm_name
  description = var.vm_description
  node_name   = var.proxmox_node
  vm_id       = var.vm_id
  pool_id     = var.resource_pool_id != "" ? var.resource_pool_id : null
  tags        = local.vm_tags

  bios            = var.vm_bios
  machine         = var.vm_machine
  started         = true
  on_boot         = true
  stop_on_destroy = true
  boot_order      = [var.disk_interface, var.cdrom_interface]

  cpu {
    cores   = var.vm_cores
    sockets = 1
    type    = var.cpu_type
  }

  memory {
    dedicated = var.vm_memory_mb
  }

  disk {
    datastore_id = var.disk_storage
    interface    = var.disk_interface
    size         = var.vm_disk_gb
    discard      = "on"
    iothread     = var.disk_iothread
    ssd          = var.disk_ssd
  }

  cdrom {
    enabled   = true
    file_id   = proxmox_virtual_environment_file.bootc_iso.id
    interface = var.cdrom_interface
  }

  efi_disk {
    datastore_id      = var.disk_storage
    file_format       = "raw"
    pre_enrolled_keys = true
    type              = var.efi_disk_type
  }

  network_device {
    bridge   = var.network_bridge
    model    = "virtio"
    firewall = false
  }

  operating_system {
    type = "l26"
  }

  serial_device {}
}
