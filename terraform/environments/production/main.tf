terraform {
  backend "s3" {}

  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "0.111.1"
    }
    talos = {
      source  = "siderolabs/talos"
      version = "0.11.0"
    }
  }
}

provider "proxmox" {
  endpoint = var.proxmox_endpoint
  username = var.proxmox_username
  password = var.proxmox_password
  insecure = var.proxmox_insecure
}

provider "talos" {
  # Configuration options
}

module "talos" {
  providers = {
    proxmox = proxmox
    talos   = talos
  }
  source = "../../modules/talos"
}
