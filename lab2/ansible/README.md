# Ansible Workflow

This directory provisions the art-host defined in [`inventory.ini`](./inventory.ini) using [`site.yml`](./site.yml).

## Prerequisites

- Ansible installed on your control machine.
- SSH key available at `~/.ssh/id_ed25519` (or update `inventory.ini`).
- Target host reachable at `192.168.4.200` as user `art`.

## Run Commands

From this folder:

```bash
cd lab2/ansible
```

Install required Ansible collections:

```bash
ansible-galaxy collection install -r requirements.yml
```

Verify inventory resolves correctly:

```bash
ansible-inventory --list
```

Test SSH + Ansible connectivity:

```bash
ansible art_hosts -m ping
```

Check playbook syntax before applying:

```bash
ansible-playbook site.yml --syntax-check
```

Run the full workflow:

```bash
ansible-playbook site.yml
```

Run only base hardening:

```bash
ansible-playbook site.yml --tags hardening -K
```

Run only Docker platform setup:

```bash
ansible-playbook site.yml --tags docker -K
```

Run only one Docker app role:

```bash
ansible-playbook site.yml --tags portainer -K
ansible-playbook site.yml --tags homepage -K
ansible-playbook site.yml --tags nginx-proxy-manager -K
```

## Useful Variations

Dry run (no changes):

```bash
ansible-playbook site.yml --check --diff
```

Run only one host (if you add more later):

```bash
ansible-playbook site.yml --limit art-host
```

Run with extra verbosity for debugging:

```bash
ansible-playbook site.yml -vvv
```

## Hardening Verification

Run the hardening role only:

```bash
ansible-playbook site.yml --tags hardening
```

Validate firewall rules:

```bash
ansible art_hosts -b -m command -a "ufw status verbose"
```

Validate fail2ban:

```bash
ansible art_hosts -b -m command -a "systemctl is-active fail2ban"
```

Validate unattended-upgrades settings:

```bash
ansible art_hosts -b -m command -a "grep -E 'Unattended-Upgrade::Automatic-Reboot|APT::Periodic::Unattended-Upgrade' /etc/apt/apt.conf.d/50unattended-upgrades /etc/apt/apt.conf.d/20auto-upgrades"
```

Validate Cockpit socket:

```bash
ansible art_hosts -b -m command -a "systemctl is-enabled cockpit.socket && systemctl is-active cockpit.socket"
```

Validate Cockpit firewall restriction:

```bash
ansible art_hosts -b -m command -a "ufw status verbose | grep 9090"
```

Cockpit URL from trusted LAN:

```text
https://192.168.4.200:9090
```

Note: your browser will show a certificate warning on first access because Cockpit uses a self-signed cert by default.

## App Verification

Validate Portainer stack:

```bash
ansible art_hosts -b -m command -a "docker compose -f /opt/stacks/portainer/docker-compose.yml ps"
```

Validate Homepage stack:

```bash
ansible art_hosts -b -m command -a "docker compose -f /opt/stacks/homepage/docker-compose.yml ps"
```

Validate Nginx Proxy Manager stack:

```bash
ansible art_hosts -b -m command -a "docker compose -f /opt/stacks/nginx-proxy-manager/docker-compose.yml ps"
```
