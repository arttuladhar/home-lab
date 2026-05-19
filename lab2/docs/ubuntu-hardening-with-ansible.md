# Ubuntu Hardening With Ansible

In many homelabs, hardening happens late.

You get the app working first. Then maybe you close a port. Then maybe you install fail2ban. Then maybe you decide password SSH was a bad idea after all.

That order is backwards.

Lab 2 treats host hardening as an early, explicit layer in the playbook. The point is not to create a perfect CIS-style benchmark implementation. The point is to make basic operational discipline part of the default build.

---

## What the Hardening Role Covers

The `ubuntu-hardening` role currently manages several practical controls:

- SSH port configuration
- password authentication policy
- root login policy
- public key authentication enforcement
- UFW default deny inbound / allow outbound
- explicit inbound allowlist
- Cockpit access restricted by CIDR
- Fail2ban enablement
- unattended security upgrades
- time synchronization
- a conservative sysctl baseline

The role runs first in [`site.yml`](../ansible/site.yml), which is the right instinct. Security controls should shape the host before more services are added on top.

---

## SSH Posture

The SSH section is simple but important:

- password authentication is disabled by default
- root login is disabled by default
- public key authentication is explicitly enabled

That is the right baseline for a personal server that should be manageable but not casually exposed.

The more important design lesson is that SSH policy belongs in code, not in memory. If you rebuild or repurpose the host later, the same expectations should be enforceable with a playbook run instead of a checklist.

---

## UFW as an Explicit Boundary

The firewall model is:

- deny incoming by default
- allow outgoing by default
- allow only the ports you intend to expose

That is basic hygiene, but it matters because Docker often tricks people into thinking published container ports are the whole network story. They are not. If your host firewall and your container exposure model disagree, you create confusing failure modes.

In other words:

- a container being healthy does not mean it is reachable
- a port being published does not mean it should be reachable from everywhere

The firewall is not just a protective control. It is also part of your operational truth.

---

## Cockpit and the “Admin Surface” Question

Lab 2 enables Cockpit and restricts access to trusted LAN CIDRs.

That is a reasonable compromise for a homelab where:

- browser-based host administration is useful
- remote management convenience matters
- full public exposure is unnecessary

This is a good example of practical hardening rather than ideological hardening. The goal is not zero surface area. The goal is a consciously limited and documented surface area.

---

## Fail2ban and Unattended Upgrades

Fail2ban and unattended security upgrades are both included because they defend against two very different kinds of operational laziness:

- repeated hostile or noisy login attempts
- patch lag on a server that may sit quietly for long stretches

Neither tool is exciting. That is exactly why they belong here.

Security-relevant boringness is a feature.

The role also limits unattended upgrades to security updates by default, which is a sensible middle ground for a host that should stay patched without surprising you with unrelated package churn.

---

## Sysctl Baseline

The sysctl file is intentionally conservative. It focuses on a few well-understood settings:

- disabling ICMP redirects
- disabling send/accept redirect behavior
- enabling reverse path filtering
- ignoring broadcast echo requests
- enabling TCP SYN cookies
- keeping address space randomization enabled

This is the right posture for a learning-focused homelab. You do not need an enormous kernel-tuning manifesto to get value. You need a small baseline you understand and can defend.

---

## The Most Important Pattern

The most important pattern in this role is not any individual setting.

It is that the settings are:

- versioned
- reviewable
- re-runnable
- attached to verification commands

That is what turns "I hardened the box once" into "I can explain and reproduce the host security posture later."

For the places where the current implementation still needs work, read [operational-lessons-and-backlog.md](operational-lessons-and-backlog.md) and the raw [ansible-findings-backlog.md](ansible-findings-backlog.md).
