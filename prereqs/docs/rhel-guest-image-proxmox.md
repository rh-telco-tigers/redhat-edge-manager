# RHEL 9 KVM guest image on Proxmox

Terraform needs a **RHEL 9 KVM guest** `.qcow2` available to Proxmox before (or during) `make up`.

## Why this is not “fully automatic” by default

- **Red Hat** distributes the KVM guest image from the [customer portal](https://access.redhat.com/downloads/content/479/) behind **subscription login**. Proxmox’s download-url task uses a plain **HTTPS GET** — it cannot log in to Red Hat for you.
- So **`make up`** either uses an image you **uploaded manually**, or an optional **`cloud_image_download_url`** you supply (internal mirror, artifact repo, presigned URL, etc.).

## Optional: let Proxmox download the image (Terraform)

If you set **`cloud_image_download_url`** in `terraform.tfvars` to an **`https://...`** URL your cluster can reach without interactive auth, Terraform creates **`proxmox_virtual_environment_download_file`** first, then imports that file into the VM disk.

Requirements on the Proxmox side:

- Storage **`cloud_image_import_datastore_id`** (default **`local`**) must allow content type **Import** (*Datacenter → Storage → edit → Content*).
- The API user needs permissions noted in the [provider doc](https://registry.terraform.io/providers/bpg/proxmox/latest/docs/resources/virtual_environment_download_file) (`Datastore.AllocateTemplate`, `Sys.Audit`, `Sys.Modify`).

Large images may need a higher **`cloud_image_download_timeout_seconds`** (default 3600).

---

## Manual upload (no URL)

Terraform expects the qcow2 under **node → local → import** when you are **not** using `cloud_image_download_url`.

### Download (needs Red Hat subscription)

From the portal: **Downloads → Red Hat Enterprise Linux → Product Software** → **KVM Guest Image** for RHEL 9 (x86_64), or the direct product page for [RHEL downloads](https://access.redhat.com/downloads/content/479/).

You want a single **`.qcow2`** file (KVM guest image).

### Upload to Proxmox

1. UI: **Datacenter → &lt;node&gt; → local** (type *dir* — where **import** lives).  
2. **ISO Images / Import** (or **Upload** in newer UI) → upload the qcow2.  
3. Rename if needed so the volume id matches Terraform:

   **`local:import/rhel9-guest-image.qcow2`**

   (Proxmox shows this as `import/rhel9-guest-image.qcow2` on storage `local`.)

4. Confirm on the **Proxmox node shell** (path varies by install; common locations):

   - `/var/lib/vz/import/<your-file>.qcow2` — often what `local:import/...` resolves to  
   - `/var/lib/vz/template/import/` — some setups use this layout  

   If `ls` shows no matching qcow2, Terraform will fail with something like:

   `failed to stat '/var/lib/vz/import/rhel9-guest-image.qcow2'`

   That always means: **nothing uploaded with that name**, or **`cloud_image_import_id` does not match** the volume id in **Datacenter → Storage → local → Content** (copy the exact **volid**, e.g. `local:import/redhat-image.qcow2`).

### `terraform.tfvars` (manual volid)

Set in `terraform.tfvars` when **not** using `cloud_image_download_url`:

```hcl
cloud_image_import_id = "local:import/rhel9-guest-image.qcow2"
ci_user               = "cloud-user"
```

Then `terraform apply` (or `-replace=...` if replacing an existing VM).

**Note:** If your uploaded filename differs, set `cloud_image_import_id` to the exact **volid** from **Storage → local → Content**.
