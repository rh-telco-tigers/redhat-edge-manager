# Enroll (onboard) device

**Prereqs:** bootc **base** image with enrollment config; device reaches RHEM **HTTPS/443**.

## Step 1 — CLI context

```bash
export RHEM_URL="https://CHANGEME-rhem.example.com"
flightctl login --url "$RHEM_URL"
```

## Step 2 — Boot device

- Boot from USB/ISO with **base** image.  
- Confirm network (DHCP per assumptions).

## Step 3 — List pending enrollment

```bash
flightctl get enrollmentrequests
# or per your CLI version:
# flightctl enrollmentrequest list
```

## Step 4 — Approve enrollment (UI or CLI)

**UI:** Edge Manager → enrollments → approve.

**CLI (adjust resource name to match output):**

```bash
flightctl approve enrollmentrequest CHANGEME_REQUEST_NAME
```

## Step 5 — Verify device registered

```bash
flightctl get devices
```
