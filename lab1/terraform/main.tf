terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "~> 0.70"
    }
  }
}

provider "proxmox" {
  endpoint  = var.proxmox_api_url
  api_token = "${var.proxmox_api_token_id}=${var.proxmox_api_token_secret}"
  insecure = true

  ssh {
    agent = true
  }

}

resource "proxmox_virtual_environment_vm" "docker_host" {
  name      = "docker-host-01"
  node_name = var.proxmox_node_name
  vm_id     = 100

  clone {
    vm_id = var.vm_template_id
  }

  cpu {
    cores = 2
    type  = "host"
  }

  memory {
    dedicated = 8192
  }

  disk {
    datastore_id = "local-lvm"
    size         = var.disk_size
    interface    = "scsi0"
  }

  network_device {
    bridge = var.bridge
  }

  initialization {
    user_account {
      username = var.vm_user
      keys     = var.ssh_public_keys
      password = var.vm_password
    }

    ip_config {
      ipv4 {
        address = var.vm_ip_address
        gateway = var.vm_gateway
      }
    }
  }
}
