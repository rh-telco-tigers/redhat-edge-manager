# Device Identity Or TPM Shows `Unsupported`

Example symptoms in the Edge Manager UI or `Device` YAML:

- `TPM not present or not enabled on this device`
- `Device identity - Unsupported`
- `TPM - Unsupported`

## What it means

The device is still enrolled and manageable, but Edge Manager cannot use TPM-backed identity or integrity features on that device.

This is common in lab VMs because the VM was created without a TPM device.

## Is it safe to ignore?

For a basic demo, yes.

If your goal is to demonstrate device integrity, device identity, or TPM-backed attestation, you need to fix it.

## How to confirm on the device

```bash
ls -l /dev/tpm*
sudo dmesg | grep -i tpm | tail -20
```

If no TPM device exists, you usually will not see `/dev/tpm0` or `/dev/tpmrm0`.

## How to fix it manually

On a physical device:

1. Reboot into firmware or BIOS settings.
2. Enable TPM 2.0.
3. If the system uses firmware TPM, enable Intel PTT or AMD fTPM.
4. Boot the system again and confirm the TPM device exists in the OS.

On a virtual machine:

1. Power off the VM.
2. Add a TPM 2.0 device in your virtualization platform.
3. Make sure the VM uses UEFI firmware.
4. Boot the VM again.
5. Confirm `/dev/tpm0` or `/dev/tpmrm0` exists.
