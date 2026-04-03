provider "proxmox" {
  endpoint = var.proxmox_endpoint
  insecure = true

  ssh {
    username = "root"

    node {
      name    = var.proxmox_node
      address = local.proxmox_ssh_host
      port    = 22
    }
  }
}

locals {
  proxmox_ssh_host = split(":", split("/", replace(replace(var.proxmox_endpoint, "https://", ""), "http://", ""))[0])[0]

  vm_description = "Frigate NVR Proxmox device"
  vm_tags = [
    "managed-by-terraform",
    "project-rhem-eap",
    "platform-proxmox",
    "os-bootc",
    "role-device",
    "workload-frigate",
  ]

  import_datastore_id     = "local"
  cloud_init_datastore_id = "local"
  uploaded_qcow2_file     = "${var.vm_name}.qcow2"
  cloud_init_file_name    = "${var.vm_name}-user-data.yaml"

  vm_cores     = 4
  vm_memory_mb = 8192
  vm_disk_gb   = 40

  secondary_disk_gb = 100
}

resource "proxmox_virtual_environment_file" "bootc_qcow2" {
  content_type   = "import"
  datastore_id   = local.import_datastore_id
  node_name      = var.proxmox_node
  overwrite      = true
  timeout_upload = 7200

  source_file {
    path      = abspath(pathexpand(var.bootc_qcow2_path))
    file_name = local.uploaded_qcow2_file
  }
}

resource "proxmox_virtual_environment_vm" "device" {
  name        = var.vm_name
  description = local.vm_description
  node_name   = var.proxmox_node
  vm_id       = var.vm_id
  tags        = local.vm_tags

  bios            = "ovmf"
  machine         = "q35"
  started         = true
  on_boot         = true
  stop_on_destroy = true
  boot_order      = ["scsi0"]

  cpu {
    cores   = local.vm_cores
    sockets = 1
    type    = "x86-64-v2-AES"
  }

  memory {
    dedicated = local.vm_memory_mb
  }

  disk {
    datastore_id = var.disk_storage
    import_from  = proxmox_virtual_environment_file.bootc_qcow2.id
    interface    = "scsi0"
    size         = local.vm_disk_gb
    discard      = "on"
    iothread     = true
    ssd          = true
  }

  disk {
    datastore_id = var.disk_storage
    interface    = "scsi1"
    size         = local.secondary_disk_gb
    discard      = "on"
    iothread     = true
    ssd          = true
  }

  efi_disk {
    datastore_id      = var.disk_storage
    file_format       = "raw"
    pre_enrolled_keys = true
    type              = "4m"
  }

  network_device {
    bridge   = "vmbr0"
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

  serial_device {}
}
