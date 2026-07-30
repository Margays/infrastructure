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
    helm = {
      source  = "hashicorp/helm"
      version = "3.2.0"
    }
  }
}

provider "proxmox" {
  endpoint = var.proxmox_endpoint
  username = var.proxmox_username
  password = var.proxmox_password
  insecure = var.proxmox_insecure
}

provider "talos" {}

provider "helm" {}

module "talos" {
  providers = {
    proxmox = proxmox
    talos   = talos
    helm    = helm
  }
  source        = "../../modules/talos"
  configuration = yamldecode(file(var.config_path))
}

resource "local_file" "kubeconfig" {
  content  = module.talos.kubeconfig
  filename = "./kubeconfig"
}

output "kubeconfig" {
  value     = module.talos.kubeconfig
  sensitive = true
}
