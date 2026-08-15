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

locals {
  kubeconfig_path = "~/.kube/config"

  existing_kubeconfig = try(yamldecode(file(local.kubeconfig_path)), {})

  new_kubeconfig = yamldecode(module.talos.kubeconfig.kubeconfig_raw)

  existing_clusters = lookup(local.existing_kubeconfig, "clusters", [])
  existing_contexts = lookup(local.existing_kubeconfig, "contexts", [])
  existing_users    = lookup(local.existing_kubeconfig, "users", [])

  new_clusters = lookup(local.new_kubeconfig, "clusters", [])
  new_contexts = lookup(local.new_kubeconfig, "contexts", [])
  new_users    = lookup(local.new_kubeconfig, "users", [])

  merged_clusters = values({ for c in concat(local.existing_clusters, local.new_clusters) : c.name => c })
  merged_contexts = values({ for c in concat(local.existing_contexts, local.new_contexts) : c.name => c })
  merged_users    = values({ for u in concat(local.existing_users, local.new_users) : u.name => u })

  merged_kubeconfig = merge(
    local.existing_kubeconfig,
    {
      clusters = local.merged_clusters,
      contexts = local.merged_contexts,
      users    = local.merged_users,
      # prefer new current-context if provided, otherwise keep existing
      "current-context" = lookup(local.new_kubeconfig, "current-context", lookup(local.existing_kubeconfig, "current-context", ""))
    }
  )

  merged_kubeconfig_yaml = yamlencode(local.merged_kubeconfig)
}

resource "local_file" "kubeconfig" {
  filename = "~/.kube/config"
  # Merge the new kubeconfig into any existing kubeconfig, preferring
  # entries from the new config when names collide.
  content    = local.merged_kubeconfig_yaml
  depends_on = [module.talos]
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
