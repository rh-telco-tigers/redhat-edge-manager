# Security & compliance

**Status:** Test plan marked **TO DO** for SA/SSA/customer detail — this lab is a **checklist shell** you can tighten once policies are fixed.

**Prereqs (from plan):** RHEL 9/10 + RHEM; AAP or OpenShift; secure network; RBAC; New Relic keys. **Report:** SSM agent installed (scan → AWS / Power BI).

## Step 1 — RBAC review

```text
[ ] Admin vs operator roles documented
[ ] Least-privilege accounts for EAP
```

## Step 2 — TLS / connectivity

```bash
# Example: verify API endpoint TLS from jump host
export RHEM_URL="https://CHANGEME-rhem.example.com"
curl -svI "$RHEM_URL" 2>&1 | head -20
```

## Step 3 — Patch / config automation (AAP / OpenShift)

```text
[ ] Link to playbook / policy that enforces patch baseline
[ ] CIS / internal benchmark target named (e.g. CIS RHEL 9)
```

## Step 4 — Container compliance checks

```text
[ ] Image scan tool + pass/fail criteria
[ ] Central audit log location
```

## Step 5 — SSM + dashboards

```text
[ ] SSM agent present on app image device
[ ] Evidence: AWS / Power BI dashboard or export
```
