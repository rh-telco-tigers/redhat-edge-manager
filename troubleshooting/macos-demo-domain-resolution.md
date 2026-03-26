# macOS Does Not Resolve The Demo Domain Even Though `/etc/resolv.conf` Looks Correct

## What it means

On macOS, most applications do not use `/etc/resolv.conf` directly. The system resolver uses `scutil` and optional per-domain resolver files.

## How to fix it manually

Create a resolver file for the demo domain:

```bash
sudo mkdir -p /etc/resolver
printf 'nameserver 192.168.4.30\n' | sudo tee /etc/resolver/rhem-eap.lan >/dev/null
sudo dscacheutil -flushcache
sudo killall -HUP mDNSResponder
```

Then verify:

```bash
scutil --dns | grep -A5 'rhem-eap.lan'
dscacheutil -q host -a name rhem.rhem-eap.lan
```
