terraform {
  backend "s3" {
        bucket = "tfstate"                  # Name of the S3 bucket
        endpoints = {
            s3 = var.s3_endpoint            # Minio endpoint
        }
        key = var.project_name + ".tfstate" # Name of the tfstate file

        access_key = var.s3_access_key      # Access and secret keys
        secret_key = var.s3_secret_key

        region = "main"                     # Region validation will be skipped
        skip_credentials_validation = true  # Skip AWS related checks and validations
        skip_requesting_account_id = true
        skip_metadata_api_check = true
        skip_region_validation = true
        use_path_style = true               # Enable path-style S3 URLs (https://<HOST>/<BUCKET> https://developer.hashicorp.com/terraform/language/settings/backends/s3#use_path_style
    }

  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "0.111.1"
    }
  }
}

provider "proxmox" {
  endpoint = var.proxmox_endpoint
  username = var.proxmox_username
  password = var.proxmox_password
  insecure = var.proxmox_insecure
}

resource "proxmox_virtual_environment_download_file" "talos_iso" {
  content_type = "iso"
  datastore_id = "truenas-nfs"
  node_name    = "minisforum"
  url          = "https://factory.talos.dev/image/9c1d1b442d73f96dcd04e81463eb20000ab014062d22e1b083e1773336bc1dd5/v1.13.7/nocloud-amd64.iso"
  file_name    = "talos.iso"
}
