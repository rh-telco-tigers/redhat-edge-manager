# Device monitoring and log gathering

**Prereqs:** UI/CLI access to RHEM. For **Alertmanager → SolarWinds/SNMP**, plan references webhook + translator (e.g. snmp_notifier); RHEM team documents to webhook boundary; customer owns downstream integration.

## Step 1 — UI: device resources

Open device in Edge Manager → **monitoring** / resource views (*Monitoring device resources*).

## Step 2 — CLI: device status (adjust to your CLI)

```bash
export RHEM_URL="https://rhem.rhem-eap.lan:3443"
flightctl login "$RHEM_URL"
flightctl get devices
flightctl get device CHANGEME_DEVICE -o yaml
```

## Step 3 — Custom monitors (if product supports)

Document the UI/CLI path you used to add **CPU / memory / disk** thresholds or alerts.

```text
CHANGEME: steps or YAML reference
```

## Step 4 — Must-gather (agent / RHEM troubleshooting)

Follow *Must-gather procedure for Red Hat Edge Manager Agent*. Paste your approved command:

```bash
# CHANGEME — official must-gather image / oc adm / flightctl support bundle
# mkdir -p ./support && cd ./support
# podman run --rm ... must-gather ...
ls -la ./support
```
