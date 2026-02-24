variable "proxmox_api_url" {
  description = "Proxmox API base URL (e.g. https://proxmox:8006/api2/json)"
  type        = string
}

variable "proxmox_api_token_id" {
  description = "Proxmox API token ID (e.g. user@pam!terraform)"
  type        = string
  sensitive   = true
}

variable "proxmox_api_token_secret" {
  description = "Proxmox API token secret"
  type        = string
  sensitive   = true
}

variable "proxmox_node_name" {
  description = "Proxmox node name where the VM will be created"
  type        = string
}

variable "vm_template_id" {
  description = "VM ID of the Ubuntu cloud-init template to clone"
  type        = number
  default     = 9000
}

variable "bridge" {
  description = "Network bridge for the VM (e.g. vmbr0)"
  type        = string
  default     = "vmbr0"
}

variable "vm_user" {
  description = "Username for the VM's default user account"
  type        = string
  default     = "ubuntu"
}

variable "disk_size" {
  description = "Disk size for the VM in GB"
  type        = number
  default     = 20
}

variable "ssh_public_keys" {
  description = "List of SSH public keys to authorize on the VM"
  type        = list(string)
}
