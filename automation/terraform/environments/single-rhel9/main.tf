provider "proxmox" {
  endpoint = var.proxmox_endpoint
  insecure = var.proxmox_insecure
}

resource "proxmox_virtual_environment_pool" "single" {
  comment = "Generic RHEL 9 VM automation"
  pool_id = var.resource_pool_id
}

module "vm" {
  source = "../../modules/rhel9_vm"

  proxmox_node                         = var.proxmox_node
  pool_id                              = proxmox_virtual_environment_pool.single.pool_id
  vm_role                              = var.vm_role
  vm_name                              = var.vm_name
  fqdn                                 = "${var.dns_name}.${var.dns_domain}"
  vm_description                       = var.vm_description
  vm_id                                = var.vm_id
  vm_cores                             = var.vm_cores
  vm_memory_mb                         = var.vm_memory_mb
  vm_disk_gb                           = var.vm_disk_gb
  network_bridge                       = var.network_bridge
  disk_storage                         = var.disk_storage
  disk_interface                       = var.disk_interface
  disk_iothread                        = var.disk_iothread
  disk_ssd                             = var.disk_ssd
  cpu_type                             = var.cpu_type
  cloud_image_import_id                = var.cloud_image_import_id
  cloud_image_download_url             = var.cloud_image_download_url
  cloud_image_import_datastore_id      = var.cloud_image_import_datastore_id
  cloud_image_download_file_name       = var.cloud_image_download_file_name
  cloud_image_download_timeout_seconds = var.cloud_image_download_timeout_seconds
  cloud_image_download_verify_tls      = var.cloud_image_download_verify_tls
  cloud_image_download_overwrite       = var.cloud_image_download_overwrite
  ci_user                              = var.ci_user
  ssh_public_key                       = var.ssh_public_key
  extra_tags                           = var.vm_tags
  ipv4_use_dhcp                        = var.ipv4_use_dhcp
  ipv4_cidr                            = var.ipv4_cidr
  ipv4_gateway                         = var.ipv4_gateway
  dns_servers                          = var.dns_servers
  dns_domain                           = var.dns_domain
}
