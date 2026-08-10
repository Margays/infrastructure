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

resource "vault_kubernetes_secret_backend" "config" {
  path                 = format("kubernetes/%s", module.talos.name)
  description          = format("%s kubernetes secrets engine", module.talos.name)
  kubernetes_host      = module.talos.api_endpoint
  kubernetes_ca_cert   = base64decode(module.talos.kubeconfig.kubernetes_client_configuration.ca_certificate)
  service_account_jwt  = data.kubernetes_secret.external_secrets_sa_token.data["token"]
  disable_local_ca_jwt = false
}

resource "vault_kubernetes_secret_backend_role" "role" {
  backend                       = vault_kubernetes_secret_backend.config.path
  name                          = format("%s-service-account-role", module.talos.name)
  allowed_kubernetes_namespaces = ["*"]
  token_max_ttl                 = 43200
  token_default_ttl             = 3600
  service_account_name          = local.external_secrets_sa_name
  kubernetes_role_type          = "ClusterRole"
}

ephemeral "vault_kubernetes_service_account_token" "token" {
  backend              = vault_kubernetes_secret_backend.config.path
  role                 = vault_kubernetes_secret_backend_role.role.name
  kubernetes_namespace = local.external_secrets_namespace
  mount_id             = vault_kubernetes_secret_backend.config.id
}
