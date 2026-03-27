# Extra Notes

Use `extras/` for supporting operational notes that are useful during demos and lab work, but are not required setup steps.

## Pages

- [trusting-lab-certificates.md](trusting-lab-certificates.md) — how to trust the Edge Manager certificate on your workstation so the browser and `flightctl` do not need insecure overrides
- [changing-edge-manager-base-domain.md](changing-edge-manager-base-domain.md) — how to change `global.baseDomain`, rotate the built-in service certificates, and recover if a certificate change goes wrong
- [cloudflare-tunnel-edge-manager.md](cloudflare-tunnel-edge-manager.md) — how to publish Edge Manager through Cloudflare Tunnel with a real public DNS name and then rotate the built-in certificates to match
- [publishing-images-to-satellite-registry.md](publishing-images-to-satellite-registry.md) — shared Satellite registry setup for the manual bootc and application labs
- [publishing-images-to-quay-registry.md](publishing-images-to-quay-registry.md) — shared Quay registry setup for manual labs that use a public OCI registry instead of Satellite
