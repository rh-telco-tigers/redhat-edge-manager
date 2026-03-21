locals {
  ipv4_address           = var.ipv4_use_dhcp ? "dhcp" : var.ipv4_cidr
  cloud_disk_import_from = var.cloud_image_download_url != "" ? proxmox_virtual_environment_download_file.guest[0].id : var.cloud_image_import_id
  vm_tags = distinct(concat([
    "managed-by-terraform",
    "project-rhem-eap",
    "platform-proxmox",
    "os-rhel",
    "role-${var.vm_role}",
  ], var.extra_tags))
}

resource "proxmox_virtual_environment_vm" "this" {
  name        = var.vm_name
  description = var.vm_description
  node_name   = var.proxmox_node
  vm_id       = var.vm_id
  pool_id     = var.pool_id != "" ? var.pool_id : null
  tags        = local.vm_tags

  stop_on_destroy = var.stop_on_destroy

  agent {
    enabled = true
    type    = "virtio"
  }

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
    import_from  = local.cloud_disk_import_from
    interface    = var.disk_interface
    size         = var.vm_disk_gb
    discard      = "on"
    iothread     = var.disk_iothread
    ssd          = var.disk_ssd
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

  initialization {
    datastore_id = var.disk_storage

    dns {
      domain  = var.dns_domain
      servers = var.dns_servers
    }

    ip_config {
      ipv4 {
        address = local.ipv4_address
        gateway = var.ipv4_use_dhcp ? null : var.ipv4_gateway
      }
    }

    user_account {
      username = var.ci_user
      keys     = [trimspace(var.ssh_public_key)]
    }
  }
}
