# Building a Production-Grade Homelab From Scratch

> Before diving in, read the [Ansible-First Homelab Blueprint](docs/ansible-first-homelab.md) for the philosophy behind this setup: why Lab 2 intentionally drops Proxmox and Terraform, why a manually installed Ubuntu host can still be managed like code, and why simpler architecture is sometimes the more disciplined choice.

Lab 1 was about building the full pipeline: Proxmox, Terraform, Ansible, Docker, and CI/CD working together end to end.

**Lab 2 is a different lesson.**

It is not a replacement for Lab 1. It is a separate path built around a different constraint: for this use case, provisioning another VM lifecycle with Proxmox and Terraform added complexity that did not create enough value. The better move was to install Ubuntu Server manually once, then treat everything after that point as code.

Three tools. Three layers. One opinionated, hardened host.

| Layer | Tool | What it does |
|---|---|---|
| Operating system configuration | Ansible | Hardens Ubuntu, configures SSH, firewalling, updates, and admin services |
| Runtime platform | Docker | Runs Portainer, Homepage, and Nginx Proxy Manager as managed stacks |
| Delivery | GitHub Actions | Builds and deploys the example app automatically |

The core idea is simple: **manual installation does not have to mean manual operations**.

If the base OS install is a one-time bootstrap, but every meaningful configuration decision after that lives in Ansible, you still get repeatability, reviewability, and a clear operational model.

---

## What You'll Learn

By working through Lab 2, you practice a different set of engineering judgments than Lab 1:

- **Choosing the right level of abstraction**: not every homelab needs a full virtualization automation layer
- **Ansible as the center of gravity**: host configuration, security controls, and application setup all flow through one playbook
- **Security as day-one design**: firewalling, SSH posture, fail2ban, unattended security updates, and a sysctl baseline are part of the initial build
- **Operational clarity**: a small, understandable system is easier to debug and maintain than a more "complete" one with unnecessary moving parts
- **Documenting tradeoffs honestly**: the goal is not to pretend the design is perfect; the goal is to understand why each choice was made

If Lab 1 teaches full-stack infrastructure automation, Lab 2 teaches restraint.

---

## Prerequisites

Before you start, you'll need:

- A manually installed **Ubuntu Server** host reachable over SSH
- An SSH key available on your control machine
- An Ansible control machine with access to the target host
- A GitHub repository if you want to use the example CI/CD workflow
- A Docker Hub account if you want to push container images from GitHub Actions

This lab currently targets:

- host: `art-host`
- IP: `192.168.4.200`
- SSH user: `art`

Those values live in [`ansible/inventory.ini`](ansible/inventory.ini) and should be treated as environment-specific.

---

## Step 1 — Install Ubuntu Once, Then Stop Clicking

Lab 2 starts with a manual Ubuntu Server installation. That is an intentional boundary.

The mistake is not doing one manual install. The mistake is continuing to manage the system manually after that.

Once the machine exists and SSH works, the rest of the system should be driven from code. That means:

- SSH settings are managed in Ansible
- firewall rules are managed in Ansible
- package policy is managed in Ansible
- Docker stack definitions are managed in Ansible
- application deployment is managed in CI/CD

This split keeps the bootstrap simple without giving up infrastructure discipline.

---

## Step 2 — Use Ansible as the Control Plane

> *"If the host is real but the configuration is not reproducible, you still have a snowflake."*

In Lab 2, Ansible is no longer just a post-provisioning helper. It becomes the primary control plane.

The main playbook is small by design:

```yaml
- name: Setup ART Docker Hosts
  hosts: art_hosts
  become: yes

  roles:
    - role: ubuntu-hardening
      tags: ["hardening"]
    - role: docker
      tags: ["docker"]
    - role: portainer
      tags: ["portainer"]
    - role: homepage
      tags: ["homepage"]
    - role: nginx-proxy-manager
      tags: ["nginx-proxy-manager"]
```

That order matters.

| Role | Why it goes first or later |
|---|---|
| `ubuntu-hardening` | Establishes the security baseline before application exposure grows |
| `docker` | Prepares the runtime platform used by the app roles |
| `portainer` | Adds container management UI |
| `homepage` | Adds service discovery/dashboard capability |
| `nginx-proxy-manager` | Adds reverse-proxy and ingress management |

This is cleaner than letting hardening become a scattered collection of one-off shell commands after the fact.

For run instructions, validation commands, and tag-level execution patterns, see [ansible/README.md](ansible/README.md).

---

## Step 3 — Harden the Host Before You Scale the Apps

Lab 2’s biggest architectural difference is that host hardening is a first-class role, not a side note.

The `ubuntu-hardening` role currently manages:

- SSH port and authentication policy
- root login restrictions
- UFW default deny inbound / allow outbound policy
- explicit allowlists for required ports
- Fail2ban
- unattended security upgrades
- Cockpit with LAN-restricted access
- `systemd-timesyncd`
- a conservative network/kernel sysctl baseline

Default values live in [`ansible/roles/ubuntu-hardening/defaults/main.yml`](ansible/roles/ubuntu-hardening/defaults/main.yml), including:

- SSH password authentication disabled
- root login disabled
- UFW enabled
- unattended security-only upgrades enabled
- Cockpit enabled on `9090`, restricted to `192.168.4.0/24`

The larger lesson is not "use these exact settings forever." It is this:

**security controls should be versioned, reviewable, and repeatable just like app deployment.**

For the deeper walkthrough, read [docs/ubuntu-hardening-with-ansible.md](docs/ubuntu-hardening-with-ansible.md).

---

## Step 4 — Keep Apps Boring

The application layer is intentionally straightforward:

- Portainer for container visibility and management
- Homepage for a dashboard
- Nginx Proxy Manager for ingress and certificate management

Each service is deployed as a dedicated Compose stack through its own Ansible role. That gives you:

- clean ownership boundaries
- templated configuration
- easier per-service troubleshooting
- the ability to re-run the playbook without manually reconstructing the host

This isn't glamorous, but that is part of the point. Homelabs become fragile when every service has a different setup pattern and every rebuild requires memory instead of code.

---

## Step 5 — Add CI/CD Where It Actually Helps

Lab 2 still includes a GitHub Actions workflow for the sample app, because app delivery benefits from automation even when infrastructure provisioning is intentionally simplified.

That separation is worth noticing:

- the **host lifecycle** is simpler than Lab 1
- the **configuration lifecycle** is stronger than a purely manual server
- the **application delivery lifecycle** can still be automated

This is the right kind of compromise. You are simplifying the layer that did not add enough value, not abandoning automation altogether.

---

## Supporting Reading

Use these docs alongside the main walkthrough:

| Path | Purpose |
|---|---|
| [docs/ansible-first-homelab.md](docs/ansible-first-homelab.md) | Why Lab 2 exists and when Ansible-first is the right choice |
| [docs/ubuntu-hardening-with-ansible.md](docs/ubuntu-hardening-with-ansible.md) | Detailed walkthrough of the hardening model and operational intent |
| [docs/operational-lessons-and-backlog.md](docs/operational-lessons-and-backlog.md) | What this lab taught, where it is still rough, and what should improve next |
| [docs/ansible-findings-backlog.md](docs/ansible-findings-backlog.md) | Raw findings list and concrete remediation backlog |
| [ansible/README.md](ansible/README.md) | Execution and verification commands |

---

## Directory Layout

| Path | Purpose |
|---|---|
| [`ansible/`](ansible/) | Primary control plane for host hardening and service deployment |
| [`ansible/roles/ubuntu-hardening/`](ansible/roles/ubuntu-hardening/) | SSH, firewall, fail2ban, updates, Cockpit, sysctl baseline |
| [`ansible/roles/docker/`](ansible/roles/docker/) | Docker Engine and runtime setup |
| [`ansible/roles/portainer/`](ansible/roles/portainer/) | Portainer deployment |
| [`ansible/roles/homepage/`](ansible/roles/homepage/) | Homepage dashboard deployment |
| [`ansible/roles/nginx-proxy-manager/`](ansible/roles/nginx-proxy-manager/) | Reverse proxy deployment |
| [`my-app/`](my-app/) | Example app artifact used by the workflow |
| [`docs/`](docs/) | Narrative docs, hardening explanation, and lessons learned |

---

## What This Lab Really Trains

Lab 1 trains full-stack infrastructure automation.

Lab 2 trains judgment.

It forces a more useful question:

> What is the smallest architecture that still gives me repeatability, security, and operational sanity?

That question matters more than whether a design looks "advanced" on paper.
