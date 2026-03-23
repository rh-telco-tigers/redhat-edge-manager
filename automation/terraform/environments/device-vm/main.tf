provider "proxmox" {
  endpoint = var.proxmox_endpoint
  insecure = var.proxmox_insecure

  ssh {
    username = var.proxmox_ssh_username

    node {
      name    = var.proxmox_node
      address = local.proxmox_ssh_host
      port    = var.proxmox_ssh_port
    }
  }
}

locals {
  proxmox_ssh_host = var.proxmox_ssh_host != "" ? var.proxmox_ssh_host : split(":", split("/", replace(replace(var.proxmox_endpoint, "https://", ""), "http://", ""))[0])[0]
  vm_tags = distinct(concat([
    "managed-by-terraform",
    "project-rhem-eap",
    "platform-proxmox",
    "os-bootc",
    "role-device",
  ], var.vm_tags))
}

resource "proxmox_virtual_environment_file" "bootc_qcow2" {
  content_type   = "import"
  datastore_id   = var.import_datastore_id
  node_name      = var.proxmox_node
  overwrite      = true
  timeout_upload = var.timeout_upload

  source_file {
    path      = abspath(pathexpand(var.bootc_qcow2_path))
    file_name = var.uploaded_qcow2_file_name
  }
}

resource "proxmox_virtual_environment_file" "cloud_init_user_data" {
  count = var.cloud_init_user_data_path != "" ? 1 : 0

  content_type = "snippets"
  datastore_id = var.cloud_init_datastore_id
  node_name    = var.proxmox_node
  overwrite    = true

  source_file {
    path      = abspath(pathexpand(var.cloud_init_user_data_path))
    file_name = var.cloud_init_file_name
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
  boot_order      = [var.disk_interface]

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
    import_from  = proxmox_virtual_environment_file.bootc_qcow2.id
    interface    = var.disk_interface
    size         = var.vm_disk_gb
    discard      = "on"
    iothread     = var.disk_iothread
    ssd          = var.disk_ssd
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

  agent {
    enabled = true
    timeout = "15m"
    trim    = false
    type    = "virtio"
  }

  operating_system {
    type = "l26"
  }

  dynamic "initialization" {
    for_each = var.cloud_init_user_data_path != "" ? [1] : []
    content {
      datastore_id      = var.disk_storage
      interface         = "ide2"
      user_data_file_id = proxmox_virtual_environment_file.cloud_init_user_data[0].id
    }
  }

  serial_device {}
}
