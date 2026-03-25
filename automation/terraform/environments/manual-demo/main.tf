provider "proxmox" {
  endpoint = var.proxmox_endpoint
  insecure = var.proxmox_insecure
}

locals {
  enabled_vms = {
    for key, vm in var.vms : key => vm
    if vm.enabled
  }

  dns_vm = try(local.enabled_vms["dns"], null)

  effective_ssh_public_key = trimspace(
    var.ssh_public_key != "" ? var.ssh_public_key : (
      var.ssh_public_key_path != "" ? file(pathexpand(var.ssh_public_key_path)) : ""
    )
  )

  dns_vm_ip = local.dns_vm == null ? "" : (
    local.dns_vm.ipv4_use_dhcp ? "" : split("/", local.dns_vm.ipv4_cidr)[0]
  )

  cloud_init_dns_servers = local.dns_vm_ip != "" ? distinct(concat([local.dns_vm_ip], var.upstream_dns_servers)) : var.upstream_dns_servers

  ansible_hosts = {
    for key, vm in local.enabled_vms : vm.vm_name => {
      ansible_host = vm.ipv4_use_dhcp ? try(flatten(module.vms[key].ipv4_addresses)[0], "") : split("/", vm.ipv4_cidr)[0]
      ansible_user = var.ci_user
      demo_role    = vm.role
      dns_name     = vm.dns_name
      fqdn         = "${vm.dns_name}.${var.dns_domain}"
    }
  }

  inventory_groups = {
    for group_name in distinct(flatten([
      for _, vm in local.enabled_vms : vm.groups
      ])) : group_name => {
      hosts = {
        for _, vm in local.enabled_vms : vm.vm_name => local.ansible_hosts[vm.vm_name]
        if contains(vm.groups, group_name)
      }
    }
  }
}

resource "proxmox_virtual_environment_pool" "demo" {
  comment = "RHEM demo automation stack"
  pool_id = var.resource_pool_id
}

module "vms" {
  for_each = local.enabled_vms

  source = "../../modules/rhel9_vm"

  proxmox_node                         = var.proxmox_node
  pool_id                              = proxmox_virtual_environment_pool.demo.pool_id
  vm_role                              = each.value.role
  vm_name                              = each.value.vm_name
  fqdn                                 = "${each.value.dns_name}.${var.dns_domain}"
  vm_description                       = each.value.vm_description
  vm_id                                = each.value.vm_id
  vm_cores                             = each.value.vm_cores
  vm_memory_mb                         = each.value.vm_memory_mb
  vm_disk_gb                           = each.value.vm_disk_gb
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
  ssh_public_key                       = local.effective_ssh_public_key
  extra_tags                           = each.value.extra_tags
  ipv4_use_dhcp                        = each.value.ipv4_use_dhcp
  ipv4_cidr                            = each.value.ipv4_cidr
  ipv4_gateway                         = each.value.ipv4_gateway != "" ? each.value.ipv4_gateway : var.default_ipv4_gateway
  dns_servers                          = local.cloud_init_dns_servers
  dns_domain                           = var.dns_domain
}

resource "local_file" "ansible_inventory" {
  count    = var.generate_ansible_inventory ? 1 : 0
  filename = abspath("${path.module}/${var.ansible_inventory_output_path}")
  content = yamlencode({
    all = {
      children = merge({
        managed_rhel_hosts = {
          hosts = local.ansible_hosts
        }
      }, local.inventory_groups)
    }
  })
}
