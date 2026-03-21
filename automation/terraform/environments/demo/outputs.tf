output "vm_names" {
  value       = { for key, vm in module.vms : key => vm.vm_name }
  description = "VM names by logical key"
}

output "vm_ipv4_addresses" {
  value = {
    for key, vm in module.vms : key => try(flatten(vm.ipv4_addresses), [])
  }
  description = "Guest-agent IPv4 addresses by logical key"
}

output "vm_fqdns" {
  value       = { for key, vm in module.vms : key => vm.fqdn }
  description = "Expected DNS names by logical key"
}

output "ansible_inventory_path" {
  value       = var.generate_ansible_inventory ? abspath("${path.module}/${var.ansible_inventory_output_path}") : ""
  description = "Generated Ansible inventory path"
}
