# Proxmox and Ubuntu template setup

- [Proxmox and Ubuntu template setup](#proxmox-and-ubuntu-template-setup)
  - [Proxmox host](#proxmox-host)
  - [Ubuntu cloud-init template (VM ID 9000)](#ubuntu-cloud-init-template-vm-id-9000)
  - [API access for Terraform](#api-access-for-terraform)


Before running Terraform, you need a Proxmox host and an Ubuntu cloud-init template (VM ID 9000). This doc describes the manual steps. For a step-by-step shell-based guide using the Proxmox CLI, see [ubuntu-cloud-init.md](ubuntu-cloud-init.md).

## Proxmox host

- Install [Proxmox VE](https://www.proxmox.com/en/downloads) on your physical host or hypervisor.
- Ensure the Proxmox API is reachable (default port **8006**, HTTPS).
- Create a Linux bridge for VMs (e.g. **vmbr0**) if one does not exist. VMs will use this for network access.

## Ubuntu cloud-init template (VM ID 9000)

1. **Create a new VM** in the Proxmox UI:
   - VM ID: **9000**
   - Name: e.g. `ubuntu-cloud-template`
   - Use default or minimal settings for disk/CPU/RAM; you will turn this into a template.

2. **Attach an Ubuntu cloud image**:
   - Download an Ubuntu Cloud Image (e.g. [Ubuntu 22.04 Cloud](https://cloud-images.ubuntu.com/noble/current/)).
   - Attach it as the VM’s disk (or use as a base and configure as needed).

3. **Configure cloud-init**:
   - In the VM’s Cloud-Init settings, set:
     - User name and SSH public key (so you can SSH after clone).
     - Optional: static IP or DHCP.
   - Ensure the cloud-init drive is attached so cloned VMs get the same cloud-init behavior.

4. **Install QEMU guest agent** (recommended for Proxmox):
   - Start the VM, SSH in, and install `qemu-guest-agent`.
   - Shut down the VM.

5. **Convert to template**:
   - In the Proxmox UI, right-click the VM → **Convert to template**.
   - Template 9000 is now used by Terraform to clone `docker-host-01`.

## API access for Terraform

- Create a Proxmox API token (or dedicated user) with privileges to create, clone, and delete VMs on the target node.
- **Do not put secrets in the repo.** Use one of:
  - Environment variables (e.g. `PROXMOX_VE_ENDPOINT`, `PROXMOX_VE_USERNAME`, `PROXMOX_VE_PASSWORD` or token), or
  - A local `terraform.tfvars` file that is listed in `.gitignore`.
- Document in your team how to obtain and set these credentials.

After the template and API access are in place, proceed with [Terraform](../terraform/) in this lab.
