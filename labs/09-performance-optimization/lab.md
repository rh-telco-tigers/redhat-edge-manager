# Performance optimization

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
