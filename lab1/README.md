# Lab 1: Homelab DevOps blueprint

Infrastructure as code (Terraform), configuration management (Ansible), containerized app (Docker), and CI/CD (GitHub Actions). Everything is under `lab1/` so the environment can be rebuilt from code.

**Layers:** Terraform provisions the VM on Proxmox → Ansible configures the Docker host → Docker runs the static site → GitHub Actions builds, pushes, and deploys on push.

## Prerequisites

- Proxmox VE host with API access
- Ubuntu cloud-init template (VM ID 9000) — see [docs/proxmox-setup.md](docs/proxmox-setup.md)
- GitHub repo (for Actions)
- Docker Hub or GitHub Container Registry account (for image push)

## Quick start

1. **Create the Proxmox template**  
   Follow [docs/proxmox-setup.md](docs/proxmox-setup.md). For a detailed shell-based guide (VM ID 9000, Ubuntu 22.04), see [docs/ubuntu-cloud-init.md](docs/ubuntu-cloud-init.md).

2. **Terraform (from `lab1/terraform/`)**
   - Copy `terraform.tfvars.example` to `terraform.tfvars` and set Proxmox URL, token, node name, and template ID.
   - Run: `terraform init`, `terraform validate`, `terraform plan`, then `terraform apply`.

3. **Ansible (from `lab1/ansible/`)**
   - Edit `inventory.ini` and set the IP or hostname of `docker-host-01` (from Proxmox/Terraform).
   - Run: `ansible-playbook -i inventory.ini site.yml`.

4. **Server deploy path**
   - On the Docker host, create `/opt/my-app` and add a `docker-compose.yml` that uses your image (e.g. `youruser/myapp:latest`). You can copy from [my-app/docker-compose.yml](my-app/docker-compose.yml) and replace `youruser` with your Docker Hub username.

5. **GitHub Actions**
   - For workflows to run, copy `lab1/.github` to your repo root as `.github` (GitHub only runs workflows from the root). The workflow expects `lab1` as a subfolder of the repo (it uses paths `lab1/my-app/**` and context `./lab1/my-app`). If this repo *is* your repo root, edit the workflow to use `my-app/**` and `./my-app` instead.
   - In the repo: Settings → Secrets and variables → Actions. Add:
     - `DOCKER_USERNAME`, `DOCKER_PASSWORD`
     - `SSH_PRIVATE_KEY` (key that can SSH to the Docker host)
     - `DEPLOY_HOST`, `DEPLOY_USER` (Docker host IP/hostname and SSH user).
   - Push to `main` to build the image, push it, and deploy (SSH to host → `docker compose pull && docker compose up -d`).

## Directory layout

| Path | Purpose |
|------|--------|
| [terraform/](terraform/) | Proxmox VM (docker-host-01) definition |
| [ansible/](ansible/) | Docker install and host config (inventory, playbook, `docker` role) |
| [my-app/](my-app/) | Static site app (Dockerfile, index.html, docker-compose) |
| [.github/workflows/](.github/workflows/) | Build and deploy workflow |

**Secrets:** Do not commit `terraform.tfvars`, `.env`, or any keys. Use env vars and GitHub Actions secrets only.

## End-to-end rebuild

To validate the full pipeline:

1. Destroy the VM: from `terraform/`, run `terraform destroy`.
2. Recreate: `terraform apply`.
3. Re-run Ansible: `ansible-playbook -i inventory.ini site.yml`.
4. Push a change to the repo and confirm the workflow builds, pushes the image, and the app updates on the host.

If this sequence works, the lab is fully reproducible from code.
