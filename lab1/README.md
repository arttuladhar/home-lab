# Building a Production-Grade Homelab From Scratch

> Before diving in, read the [Homelab DevOps Blueprint](docs/homelab-blueprint.md) for the philosophy behind this setup — why infrastructure as code matters, why dashboards aren't enough, and what separates a hobby lab from an engineered system.

Most homelabs start the same way: spin up a VM, SSH in, install packages by hand, and call it done. It works. But it's also fragile — a "snowflake" server that exists only because you were there to click the right buttons at the right time.

**Lab 1 is a deliberate break from that pattern.**

Four tools. Four layers. One complete automation pipeline.

| Layer | Tool | What it does |
|---|---|---|
| Infrastructure | Terraform | Provisions the VM on Proxmox from code |
| Configuration | Ansible | Installs Docker and configures the host |
| Runtime | Docker | Runs the containerized application |
| Delivery | GitHub Actions | Builds, pushes, and deploys on every push |

Every layer has a clear responsibility. Blurring those boundaries — running config management inside Terraform, or deploying from SSH instead of a pipeline — creates systems that are harder to debug, harder to hand off, and harder to rebuild under pressure.

---

## What You'll Learn

By completing this lab, you'll practice the same patterns used in cloud-native environments:

- **Declarative infrastructure**: define *what* should exist, not *how* to create it
- **Idempotent configuration**: run your Ansible playbook 10 times; the result is always the same
- **Artifact-based deployment**: your app becomes a container image — buildable anywhere, runnable anywhere
- **Secret discipline**: no credentials in source code, ever
- **Reproducibility**: destroy everything, rebuild from scratch with a single command sequence

If that sequence works end-to-end, you're operating at a different level than someone keeping a single snowflake server alive.

---

## Prerequisites

Before you start, you'll need:

- A **Proxmox VE** host with API token access enabled
- An **Ubuntu cloud-init template** (VM ID 9000) — follow [docs/proxmox-setup.md](docs/proxmox-setup.md) to create one, or use [docs/ubuntu-cloud-init.md](docs/ubuntu-cloud-init.md) for a detailed shell-based walkthrough
- A **GitHub repository** to host the Actions workflow
- A **Docker Hub** or GitHub Container Registry account for the image push

---

## Step 1 — Infrastructure as Code with Terraform

> *"If your VM exists only because you clicked 'Create', it exists only in that moment."* — [Homelab Blueprint](docs/homelab-blueprint.md)

Terraform describes infrastructure declaratively. You define what should exist; Terraform calls the Proxmox API to make it real.

**Setup:**

```bash
cd lab1/terraform/
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars: set proxmox_url, api_token, node_name, template_id
```

**Apply:**

```bash
terraform init
terraform validate
terraform plan
terraform apply
```

Plan first. Apply second. That discipline translates directly when you're touching production infrastructure later.

> **State matters.** Terraform maintains a state file mapping declared resources to real Proxmox objects. In this lab, local state is fine — but understand that in production, state lives in a remote backend with locking. Know what you're trading off.

> **Never commit secrets.** API tokens belong in `terraform.tfvars` (which is `.gitignore`'d), not in `main.tf`. Use variables and environment injection. If you're committing secrets, you're rehearsing a very bad habit.

---

## Step 2 — Configuration Management with Ansible

Terraform handed you a blank Ubuntu VM. It didn't give you Docker, firewall rules, or a configured deployment user. That's Ansible's job.

Ansible connects over SSH, runs idempotent tasks, and leaves the machine in a known, repeatable state. No agent required.

**Setup:**

```bash
cd lab1/ansible/
# Edit inventory.ini: set the IP or hostname of docker-host-01
```

**Apply:**

```bash
ansible-playbook -i inventory.ini site.yml
```

The keyword here is **idempotent**. If Docker is already installed, Ansible won't reinstall it. If the service is running, it won't restart it unnecessarily. Run this playbook tomorrow and it won't degrade anything.

As your lab grows, Ansible roles keep things organized:

```
ansible/
├── inventory.ini
├── site.yml
└── roles/
    └── docker/
        └── tasks/main.yml
```

This isn't overengineering — it's rehearsal for environments where multiple people maintain the same automation repository.

---

## Step 3 — Containerization with Docker

Your VM is now a Docker host. Instead of installing Nginx directly onto the OS, you declare it as a container workload.

**Setup the app directory on the Docker host:**

```bash
mkdir -p /opt/my-app
# Copy lab1/my-app/docker-compose.yml to /opt/my-app/
# Replace 'youruser' with your Docker Hub username
```

A few lessons baked into the Docker layer worth internalizing:

- **Pin versions.** Don't use `latest` in production-style configs. `nginx:1.25-alpine` is explicit and reproducible.
- **Add health checks.** They determine how your stack behaves at 3 a.m. when something quietly fails.
- **Specify restart policies.** `unless-stopped` means Docker restarts your container after a reboot without intervention.

With Docker, your application becomes a portable artifact — built in CI, tagged, pushed to a registry, pulled onto any compatible host. That separation between *build* and *run* is what makes automated delivery possible.

---

## Step 4 — CI/CD and Automated Delivery

> *"Without CI/CD, deployment is an SSH habit."* — [Homelab Blueprint](docs/homelab-blueprint.md)

You log in, pull changes, restart services, hope nothing breaks. That doesn't scale, and it doesn't leave a paper trail.

With a pipeline, change is event-driven: a Git push triggers a build → produces an image → pushes it to a registry → the server pulls and restarts.

**Setup:**

1. Copy `lab1/.github` to your repository root as `.github` (GitHub only runs workflows from the root). The workflow uses paths `lab1/my-app/**` and build context `./lab1/my-app`. If `lab1/` *is* your repo root, update those paths to `my-app/**` and `./my-app`.

2. In your GitHub repo, go to **Settings → Secrets and variables → Actions** and add:

   | Secret | Value |
   |---|---|
   | `DOCKER_USERNAME` | Your Docker Hub username |
   | `DOCKER_PASSWORD` | Your Docker Hub password or access token |
   | `SSH_PRIVATE_KEY` | Private key that can SSH into the Docker host |
   | `DEPLOY_HOST` | IP address or hostname of the Docker host |
   | `DEPLOY_USER` | SSH user on the Docker host |

3. Push to `main`. The workflow builds the image, pushes it to Docker Hub, and SSHs into the host to run `docker compose pull && docker compose up -d`.

**What changes:** The server doesn't need your source code anymore. It needs a trusted, versioned image and instructions to refresh it. Every deployment is traceable to a commit hash. You've moved from manual change to controlled release.

---

## Directory Layout

| Path | Purpose |
|---|---|
| [`terraform/`](terraform/) | Proxmox VM definition — `docker-host-01` |
| [`ansible/`](ansible/) | Docker install and host configuration |
| [`my-app/`](my-app/) | Static site app (Dockerfile, index.html, docker-compose) |
| [`.github/workflows/`](.github/workflows/) | CI/CD build and deploy workflow |
| [`docs/`](docs/) | Supporting guides — Proxmox setup, cloud-init, blueprint |

> **Secrets:** Never commit `terraform.tfvars`, `.env`, or any private keys. Use environment variables and GitHub Actions secrets only.

---

## The Full Rebuild Test

The real validation of this lab isn't that it works once. It's that it can be destroyed and rebuilt from code without guesswork.

```bash
# 1. Destroy the VM
cd lab1/terraform && terraform destroy

# 2. Recreate infrastructure
terraform apply

# 3. Reconfigure the host
cd lab1/ansible && ansible-playbook -i inventory.ini site.yml

# 4. Redeploy the app
# Push a change to main — the pipeline handles the rest
```

If that sequence works end-to-end, the lab is fully reproducible. That's the bar worth clearing.

---

## What This Lab Really Trains

A well-built homelab is a rehearsal space for production responsibility. By the time you've completed Lab 1, you've practiced:

- Version-controlled infrastructure that can be reviewed in a pull request
- Idempotent configuration that's safe to re-run at any time
- Artifact-based deployment that decouples build from runtime
- Secret management that doesn't rely on hoping nobody looks at the repo
- Change management with a traceable audit trail

None of that requires a cloud budget. It requires intention — and a refusal to rely on dashboards and muscle memory when code can do the job better.

---

*Continue reading: [Homelab DevOps Blueprint](docs/homelab-blueprint.md) — the full narrative on why each layer exists and what each one trains you to think about.*
