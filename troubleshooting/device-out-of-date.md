# Device Shows `Out-of-date`

Example symptom in the UI:

- `Out-of-date`
- `Device has not yet been scheduled for update to the fleet's latest spec`

## What it means

The device is enrolled, but Edge Manager has not yet queued that device to move to the latest fleet-rendered spec.

In most cases, this means one of these:

- the device is not matched by the fleet selector
- the device does not have a fleet owner yet
- the fleet changed, but the controller has not reconciled the device yet
- the device is disconnected, paused, or still finishing earlier work
- the device labels do not match the fleet selector

## How to confirm

```bash
flightctl get devices -o wide
flightctl get device CHANGEME_DEVICE -o yaml
flightctl get fleets -o yaml
```

Focus on these fields:

- `metadata.owner`
- `metadata.labels`
- `status.updated.status`
- `status.summary.status`
- `spec.selector.matchLabels` on the fleet

## How to fix it manually

1. Confirm the device labels match the fleet selector.
2. Confirm the device is actually owned by the expected fleet.
3. Confirm the device is online.
4. If you just approved enrollment, wait a short time and check again.
5. If the labels are wrong, correct them and recheck the fleet.
6. If needed, reapply the fleet manifest:

```bash
flightctl apply -f fleet.yaml
flightctl get device CHANGEME_DEVICE -o yaml
```

When the device is successfully scheduled and reconciled, `status.updated.status` should move toward `UpToDate`.
