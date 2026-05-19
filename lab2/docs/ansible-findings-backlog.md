# Ansible Findings Backlog

## Context

- Reviewed scope: `lab2/ansible`
- Goal: identify obvious reliability/security/operational issues likely to cause future pain.
- Snapshot date: 2026-05-19
- Exposure assumptions used in review:
  - Host access model: LAN/VPN only
  - App UI access model: direct host ports are acceptable for now

## High-Priority Findings

### 1) UFW policy vs published app ports mismatch

- Why this may bite later:
  - UFW default deny inbound can block services that are published by Docker if those ports are not explicitly allowed in firewall policy, causing confusing "container is up but not reachable" behavior.
- Affected files:
  - `lab2/ansible/roles/ubuntu-hardening/defaults/main.yml`
  - `lab2/ansible/roles/portainer/defaults/main.yml`
- Concrete remediation:
  - Align firewall allowlist with intentionally exposed app ports, or stop exposing those ports directly and route through reverse proxy only.

### 2) Portainer port mapping semantics are confusing/misaligned

- Why this may bite later:
  - Current variable naming suggests HTTP UI on 9000, but mapping points to container 8000 (Edge tunnel), which can lead to incorrect troubleshooting and access assumptions.
- Affected files:
  - `lab2/ansible/roles/portainer/defaults/main.yml`
- Concrete remediation:
  - Clarify port variables and map by purpose explicitly (UI/API HTTPS on 9443; Edge 8000 only if needed).
  - Rename variables to reflect real behavior.

### 3) Bootstrap admin secrets in role defaults placeholders

- Why this may bite later:
  - Secrets-like values in defaults are easy to accidentally commit or forget to override, and placeholders can cause broken or insecure first-run behavior.
- Affected files:
  - `lab2/ansible/roles/nginx-proxy-manager/defaults/main.yml`
- Concrete remediation:
  - Move sensitive values to encrypted Ansible Vault (for example `group_vars/art_hosts/vault.yml`) and reference those variables from role defaults/tasks.

### 4) SSH host key checking disabled globally

- Why this may bite later:
  - Disabling host key checking reduces trust guarantees and increases MITM risk.
- Affected files:
  - `lab2/ansible/ansible.cfg`
- Concrete remediation:
  - Re-enable host key checking and manage known_hosts intentionally (bootstrap once, then enforce).

### 5) Floating `latest` image tags reduce reproducibility

- Why this may bite later:
  - Future runs may pull breaking image changes unexpectedly, making behavior drift across time.
- Affected files:
  - `lab2/ansible/roles/portainer/defaults/main.yml`
  - `lab2/ansible/roles/homepage/defaults/main.yml`
  - `lab2/ansible/roles/nginx-proxy-manager/defaults/main.yml`
- Concrete remediation:
  - Pin explicit image versions (or digests), then update deliberately as part of maintenance.

### 6) Sysctl task always reports changed

- Why this may bite later:
  - Constant "changed" status creates noise and hides meaningful configuration drift in playbook output.
- Affected files:
  - `lab2/ansible/roles/ubuntu-hardening/tasks/main.yml`
- Concrete remediation:
  - Make sysctl apply idempotent (for example, run reload only when sysctl config file changes).

### 7) README run commands inconsistent with sudo model

- Why this may bite later:
  - Commands that omit `-K` fail in environments without passwordless sudo, leading to first-run friction and confusion.
- Affected files:
  - `lab2/ansible/README.md`
- Concrete remediation:
  - Standardize command examples for the chosen privilege model (`-K` for prompted sudo password, or document NOPASSWD setup).

## Recommended Fix Order

1. Align firewall policy and intentionally exposed app ports.
2. Correct Portainer port variable semantics and mapping names.
3. Move admin credentials/secrets to Ansible Vault.
4. Standardize privilege escalation workflow in README (`-K` vs NOPASSWD).
5. Pin image versions instead of `latest`.
6. Re-enable host key checking with known_hosts management.
7. Clean sysctl idempotency noise.

## Commands to Validate Each Fix

### Baseline static checks

```bash
ansible-playbook site.yml --syntax-check
ansible-inventory --list
```

### Layered dry runs

```bash
ansible-playbook site.yml --tags hardening --check --diff -K
ansible-playbook site.yml --tags docker --check --diff -K
ansible-playbook site.yml --tags portainer,homepage,nginx-proxy-manager --check --diff -K
```

### Apply and verify firewall + ports

```bash
ansible-playbook site.yml -K
ansible art_hosts -b -m command -a "ufw status verbose"
ansible art_hosts -b -m command -a "ss -tulpn | rg -E ':(80|81|443|9443|9000|9090)\\b'"
```

### Verify app stacks and service state

```bash
ansible art_hosts -b -m command -a "docker compose -f /opt/stacks/portainer/docker-compose.yml ps"
ansible art_hosts -b -m command -a "docker compose -f /opt/stacks/homepage/docker-compose.yml ps"
ansible art_hosts -b -m command -a "docker compose -f /opt/stacks/nginx-proxy-manager/docker-compose.yml ps"
ansible art_hosts -b -m command -a "systemctl is-active fail2ban && systemctl is-active cockpit.socket"
```

### Verify idempotency

```bash
ansible-playbook site.yml -K
ansible-playbook site.yml -K
```

## Deferred / Nice-to-Have

- Add Molecule or CI checks for role-level validation and idempotency gates.
- Centralize repeated app-role patterns into shared task includes to reduce duplication.
- Add explicit variable validation (`assert`) for required values before deployment.
- Add optional app exposure profiles (direct ports vs reverse-proxy-only) as inventory-level toggles.
- Add changelog/release process for controlled image version bumps.
