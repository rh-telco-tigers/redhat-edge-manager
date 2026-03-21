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
