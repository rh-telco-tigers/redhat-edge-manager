#!/usr/bin/env bash
set -euo pipefail

tmpfile="$(mktemp)"
trap 'rm -f "$tmpfile"' EXIT

awk '
/^# BEGIN RHEM DEMO HOSTS$/ {skip=1; next}
/^# END RHEM DEMO HOSTS$/ {skip=0; next}
!skip {print}
' /etc/hosts > "$tmpfile"

cat >> "$tmpfile" <<'EOF'
# BEGIN RHEM DEMO HOSTS
192.168.4.30 dns.rhem-eap.lan dns
192.168.4.35 rhem.rhem-eap.lan rhem
192.168.4.36 keycloak.rhem-eap.lan keycloak
192.168.4.37 aap.rhem-eap.lan aap
192.168.4.38 satellite.rhem-eap.lan satellite
# END RHEM DEMO HOSTS
EOF

install -m 0644 "$tmpfile" /etc/hosts
