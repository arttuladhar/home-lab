- [Building the Base – Creating an Ubuntu Cloud-Init Template in Proxmox](#building-the-base--creating-an-ubuntu-cloud-init-template-in-proxmox)
  - [The Technology: What is Cloud-Init?](#the-technology-what-is-cloud-init)
  - [Guided Lab: Creating the Template via Proxmox Shell](#guided-lab-creating-the-template-via-proxmox-shell)
  - [The Result](#the-result)

# Building the Base – Creating an Ubuntu Cloud-Init Template in Proxmox

Before you can use Infrastructure as Code (IaC) to spin up dozens of virtual machines, you need a master image to clone them from. In the Proxmox world, the best practice is to build a **Cloud-Init Template** using an official Ubuntu Cloud Image.

## The Technology: What is Cloud-Init?

**Definition:** Cloud-Init is the industry standard method for cross-platform cloud instance initialization.

**How it Works:** When you download a standard Ubuntu desktop or server ISO, you have to boot it up and manually click through an installation wizard (setting up keyboards, timezones, and users). A "Cloud Image," however, is a pre-installed, highly compressed version of the operating system.

When a VM boots from a Cloud Image, Cloud-Init intercepts the boot process. It looks at the parameters you passed to it (via Terraform or the Proxmox UI), automatically injects your SSH keys, sets your network IP addresses, creates your user accounts, and expands the hard drive to the correct size. All of this happens in milliseconds before the operating system finishes booting.

## Guided Lab: Creating the Template via Proxmox Shell

For this lab, we will use the Proxmox Shell to download the official Ubuntu 22.04 (noble Jellyfish) Cloud Image and transform it into a reusable template with the ID `9000`.

**Step 1: Access your Proxmox Shell**
Log into your Proxmox web interface, select your node (e.g., `proxmox`) on the left, and click `Shell` on the top right. You are now in the root command line of your hypervisor.

**Step 2: Download the Ubuntu Cloud Image**
We will use `wget` to download the official, pre-built image directly from Canonical (the makers of Ubuntu).

```bash
wget https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img

```

**Step 3: Create a New Virtual Machine**
We will create a basic VM container with the ID `9000`. We are giving it 2GB of RAM, 2 CPU cores, and attaching it to our default network bridge (`vmbr0`).

```bash
qm create 9000 --name "ubuntu-2204-cloudinit" --memory 2048 --cores 2 --net0 virtio,bridge=vmbr0

```

**Step 4: Import the Downloaded Disk**
Now, we import the `.img` file we downloaded in Step 2 into the Proxmox storage. *(Note: If your primary storage is named something other than `local-lvm`, replace it below).*

```bash
qm importdisk 9000 noble-server-cloudimg-amd64.img local-lvm

```

**Step 5: Attach the Disk and Configure Hardware**
The disk is imported, but we need to tell the VM to use it as a SCSI drive. We also need to add a virtual CD-ROM drive specifically for Cloud-Init to pass configuration data.

```bash
# Attach the imported disk
qm set 9000 --scsihw virtio-scsi-pci --scsi0 local-lvm:vm-9000-disk-0

# Add the Cloud-Init Drive
qm set 9000 --ide2 local-lvm:cloudinit

# Set the boot disk to the SCSI drive and configure a serial console (required by many cloud images)
qm set 9000 --boot c --bootdisk scsi0 --serial0 socket --vga serial0

```

**Step 6: Convert the VM into a Template**
Finally, we lock the VM so it can no longer be booted or modified directly. It is now a permanent template!

```bash
qm template 9000

```

## The Result

If you look at your Proxmox web interface, you will see that VM `9000` now has a slightly different icon (a document shape rather than a computer screen).

You have successfully created a pristine, master Ubuntu image. From now on, whenever you run your Terraform script, it will instantly clone this template, inject your specific IP address and SSH keys via the Cloud-Init drive, and spin up a brand new, production-ready server in seconds!