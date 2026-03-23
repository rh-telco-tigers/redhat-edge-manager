# hello-web

This folder is the source of truth for the demo application used in Lab 6.

Automation uses these same files when you run:

- `make build-app`
- `make deploy-app`

Files:

- `runtime/index.html`: the page served by the runtime container
- `runtime/Containerfile`: the runtime image definition
- `package/application.container`: the quadlet unit embedded in the package image
- `package/Containerfile`: the package image definition
- `fleet-with-app.yaml`: the Fleet manifest that adds the application through Edge Manager

Manual flow:

1. Use the files in this folder directly. If your Satellite registry path is not `satellite.rhem-eap.lan/id/1/1/...`, edit `package/application.container` and `fleet-with-app.yaml`.
2. Build and push the runtime image:

```bash
sudo podman build \
  -t "${DEMO_RUNTIME_IMAGE_REPO}:${APP_TAG}" \
  -f runtime/Containerfile \
  runtime

sudo podman push "${DEMO_RUNTIME_IMAGE_REPO}:${APP_TAG}"
```

3. Build and push the package image:

```bash
sudo podman build \
  -t "${DEMO_PACKAGE_IMAGE_REPO}:${APP_TAG}" \
  -f package/Containerfile \
  package

sudo podman push "${DEMO_PACKAGE_IMAGE_REPO}:${APP_TAG}"
```

4. Apply `fleet-with-app.yaml` with `flightctl`.

Automation path:

- `make build-app` copies these same files and updates the few environment-specific values automatically before it builds and pushes the images.
- `make deploy-app` copies `fleet-with-app.yaml`, updates the live image references, and applies it through Edge Manager.
