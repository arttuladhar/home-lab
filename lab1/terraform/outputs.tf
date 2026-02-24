output "vm_name" {
  description = "Name of the provisioned VM"
  value       = proxmox_virtual_environment_vm.docker_host.name
}

output "vm_id" {
  description = "Proxmox VM ID"
  value       = proxmox_virtual_environment_vm.docker_host.vm_id
}

output "vm_ip_address" {
  description = "IP address of the docker host"
  value       = proxmox_virtual_environment_vm.docker_host.ipv4_addresses
}
