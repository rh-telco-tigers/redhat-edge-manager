---
title: "Use Case 4.5.8 — Performance & optimization (EAP)"
description: "Resource tuning, scaling policies, predictive alerts — fill as customer defines."
tags: [performance, ansible, newrelic, dell]
---

# Lab 4.5.8 — Performance optimization

**Status:** Test plan **TO DO** for customer specifics — **checklist shell** for Dell R260 + New Relic + RHEM.

**Prereqs (from plan):** RHEL 9/10 + RHEM on R260; New Relic deployed; AAP playbooks for allocation/testing; **network baseline** documented.

## Step 1 — Baseline metrics (before changes)

Capture **CPU / memory / disk / network** for representative device (UI, New Relic, or CLI).

```text
CHANGEME: timestamp, device ID, screenshot or export link
```

## Step 2 — Container limits / requests

```text
[ ] Document podman / systemd unit / RHEM app spec limits
```

## Step 3 — Scaling or rebalance policy (if applicable)

```text
[ ] AAP playbook or fleet policy ID
[ ] Peak vs off-peak assumption noted
```

## Step 4 — Predictive alerts

```text
[ ] New Relic NRQL / alert condition names
[ ] Test: synthetic load or documented drill
```

## Step 5 — Success check (from test plan)

- [ ] Improved or **validated** CPU/memory efficiency vs baseline  
- [ ] Automated scaling / policy **tested** (if in scope)  
- [ ] Bottleneck alerts **fire** in a controlled test  
- [ ] SLA / downtime narrative updated for EAP  

**Done.**
