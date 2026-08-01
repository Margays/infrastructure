variable "configuration" {
  description = "Talos cluster configuration loaded from cluster.yaml."

  type = object({
    kind = string
    spec = object({
      name = string
      cluster = object({
        kubernetes_version = string
        endpoint           = string
        image              = string
      })
      nodes = list(object({
        name              = string
        role              = string
        proxmox_node_name = string
        network = object({
          address     = string
          mask        = number
          gateway     = string
          bridge      = string
          mac_address = string
          vlan_id     = number
        })
        resources = object({
          cpu    = number
          memory = number
          disk   = number
        })
      }))
      manifests = list(object({
        name       = string
        type       = string
        phase      = string
        namespace  = optional(string)
        chart      = optional(string)
        version    = optional(string)
        repository = optional(string)
        values     = optional(any)
        manifest   = optional(string)
      }))
      config_patches_directory = optional(string)
      flux = object({
        url              = string
        path             = string
        username         = string
        private_key_file = string
        patch_file       = optional(string)
      })
    })
  })

  validation {
    condition     = var.configuration.kind == "TalosCluster"
    error_message = "configuration.kind must be TalosCluster."
  }

  validation {
    condition     = length(var.configuration.spec.nodes) > 0
    error_message = "At least one node must be configured."
  }

  validation {
    condition     = length(distinct([for node in var.configuration.spec.nodes : node.name])) == length(var.configuration.spec.nodes)
    error_message = "Node names must be unique."
  }

  validation {
    condition     = alltrue([for node in var.configuration.spec.nodes : contains(["controlplane", "worker"], node.role)])
    error_message = "Each node role must be controlplane or worker."
  }

  validation {
    condition     = length([for node in var.configuration.spec.nodes : node if node.role == "controlplane"]) > 0
    error_message = "At least one controlplane node must be configured."
  }

  validation {
    condition     = alltrue([for node in var.configuration.spec.nodes : node.network.vlan_id >= 1 && node.network.vlan_id <= 4094])
    error_message = "Each VLAN ID must be between 1 and 4094."
  }

  validation {
    condition     = alltrue([for manifest in var.configuration.spec.manifests : contains(["helm", "manifest"], manifest.type)])
    error_message = "Each manifest type must be helm or manifest."
  }

  validation {
    condition     = alltrue([for manifest in var.configuration.spec.manifests : manifest.type != "helm" || (manifest.namespace != null && manifest.chart != null && manifest.version != null && manifest.repository != null && manifest.values != null)])
    error_message = "Helm manifests must define namespace, chart, version, repository, and values."
  }

  validation {
    condition     = alltrue([for manifest in var.configuration.spec.manifests : manifest.type != "manifest" || manifest.manifest != null])
    error_message = "Manifest entries must define manifest contents."
  }
}
