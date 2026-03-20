# Optional: Proxmox downloads the qcow2 server-side (download-url API) before VM create.
# Set cloud_image_download_url in terraform.tfvars when you have an HTTPS URL Proxmox can fetch
# (internal mirror, presigned link, etc.). Red Hat CDN URLs typically need auth — manual upload may still be required.

resource "proxmox_virtual_environment_download_file" "guest" {
  count = var.cloud_image_download_url != "" ? 1 : 0

  node_name    = var.proxmox_node
  content_type = "import"
  datastore_id = var.cloud_image_import_datastore_id
  url          = var.cloud_image_download_url
  file_name    = var.cloud_image_download_file_name

  upload_timeout = var.cloud_image_download_timeout_seconds
  verify         = var.cloud_image_download_verify_tls
  overwrite      = var.cloud_image_download_overwrite
}
