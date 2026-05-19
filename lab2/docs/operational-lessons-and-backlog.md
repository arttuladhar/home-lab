# Operational Lessons and Backlog

Lab 2 is valuable partly because it is not polished all the way through.

The repo already contains a raw findings list in [ansible-findings-backlog.md](ansible-findings-backlog.md). That file is useful as a working backlog. This document is the higher-level interpretation: what the lab teaches, what is still rough, and what those rough edges say about operating a real system.

---

## Lesson 1: Simpler Architecture Still Needs Sharp Edges Filed Down

Removing Proxmox and Terraform from the center of the design reduced complexity.

It did not remove the need for rigor.

In fact, once the architecture gets smaller, mismatches become easier to see:

- the README still reflected Lab 1 instead of Lab 2
- the GitHub Actions workflow still points at `lab1` paths
- firewall policy and exposed ports need clearer alignment
- Portainer’s published port semantics are easy to misread

This is useful. Smaller systems surface inconsistencies faster because there are fewer places to hide them.

---

## Lesson 2: “Working” and “Well Explained” Are Different States

A lot of homelab work reaches the "it works" phase and stops there.

That is fine if the goal is only a functioning machine. It is not fine if the goal is learning, repeatability, or future maintainability.

Lab 2 needed documentation not because the Ansible was absent, but because the design intent was still trapped in the operator’s head.

That is the exact point where good documentation becomes part of the engineering work rather than an afterthought.

---

## Lesson 3: Security Controls Must Agree With Service Exposure

One of the most useful findings in the current backlog is the tension between:

- UFW default deny inbound
- published Docker service ports
- the actual access model you intend

This is not just a firewall detail. It is an architecture question.

You need to decide, explicitly, whether each service is:

- directly reachable on the host
- reachable only through Nginx Proxy Manager
- reachable only from trusted LAN ranges
- not meant to be exposed at all

Until that model is explicit, operational debugging gets harder than it should be.

---

## Lesson 4: Defaults Carry Risk

Several current defaults are fine for prototyping but weak for long-term reproducibility:

- `latest` image tags
- globally disabled SSH host key checking
- placeholders or secret-like values living too close to defaults

These are common homelab shortcuts. They are also exactly the kind of shortcuts that become technical debt because they "work" long enough to stick around.

The fix is not to feel guilty about them. The fix is to name them, track them, and improve them deliberately.

---

## Recommended Next Improvements

If this were my next pass, I would tighten Lab 2 in this order:

1. Fix the documentation and workflow references so the repo describes what it actually does now.
2. Align firewall intent with real service exposure.
3. Clarify Portainer port naming and mapping.
4. Move sensitive bootstrap values toward Vault-backed variables.
5. Pin image versions instead of floating on `latest`.
6. Re-enable host key checking and manage `known_hosts` intentionally.
7. Clean up small idempotency noise like the always-changed sysctl reload.

That sequence matters. You want the repo to become understandable first, then more secure and more reproducible.

---

## Why Keep the Backlog Visible

There is a temptation to hide imperfections in learning repos.

That is the wrong instinct.

Visible backlog is useful because it shows:

- what you noticed
- what you deliberately deferred
- what still separates the current state from the target state

That is how real infrastructure work looks. Mature systems are not systems with no issues. They are systems where the issues are known, prioritized, and handled without denial.

---

## Final Takeaway

Lab 2 is not interesting because it is "complete."

It is interesting because it captures a real engineering correction:

- Lab 1 explored a broader automation stack.
- Lab 2 narrowed the scope on purpose.
- The narrower scope made hardening, clarity, and operational discipline more central.

That is real learning. Not just adding more tools, but deciding which tools are actually worth carrying.
