terraform {
  backend "s3" {}

  required_providers {
    vault = {
      source  = "hashicorp/vault"
      version = "5.10.1"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.25.0"
    }
  }
}

provider "vault" {
  address = var.vault_address
  token   = var.vault_token
}

data "vault_generic_secret" "proxmox" {
  path = "kv/proxmox"
}

module "talos" {
  source        = "../../modules/talos"
  configuration = yamldecode(file(var.config_path))
  secrets = {
    proxmox = {
      endpoint = data.vault_generic_secret.proxmox.data["endpoint"]
      username = data.vault_generic_secret.proxmox.data["username"]
      password = data.vault_generic_secret.proxmox.data["password"]
      insecure = false
    }
  }
}

resource "local_file" "kubeconfig" {
  content  = module.talos.kubeconfig.kubeconfig_raw
  filename = "./kubeconfig"
}

output "kubeconfig" {
  value     = module.talos.kubeconfig
  sensitive = true
}

provider "kubernetes" {
  host                   = module.talos.api_endpoint
  client_certificate     = base64decode(module.talos.kubeconfig.kubernetes_client_configuration.client_certificate)
  client_key             = base64decode(module.talos.kubeconfig.kubernetes_client_configuration.client_key)
  cluster_ca_certificate = base64decode(module.talos.kubeconfig.kubernetes_client_configuration.ca_certificate)
}

locals {
  external_secrets_namespace = "external-secrets"
  external_secrets_sa_name   = "external-secrets"
}

data "kubernetes_secret" "external_secrets_sa_token" {
  metadata {
    name      = "external-secrets-token"
    namespace = local.external_secrets_namespace
  }

  depends_on = [
    module.talos
  ]
}

resource "vault_auth_backend" "this" {
  type        = "kubernetes"
  path        = format("kubernetes/%s", module.talos.name)
  description = format("Kubernetes auth backend for %s cluster", module.talos.name)
}

resource "vault_kubernetes_auth_backend_config" "this" {
  backend            = vault_auth_backend.this.path
  kubernetes_host    = module.talos.api_endpoint
  kubernetes_ca_cert = base64decode(module.talos.kubeconfig.kubernetes_client_configuration.ca_certificate)
  token_reviewer_jwt = data.kubernetes_secret.external_secrets_sa_token.data["token"]
}

resource "vault_kubernetes_auth_backend_role" "external_secrets" {
  backend                          = vault_auth_backend.this.path
  role_name                        = "external-secrets"
  bound_service_account_names      = ["external-secrets"]
  bound_service_account_namespaces = ["external-secrets"]
}
