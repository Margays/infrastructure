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
        network = object({
          cni = object({
            name = string
          })
          proxy = object({
            disabled = bool
          })
        })
      })
      nodes = list(object({
        name = string
        role = string
        network = object({
          address     = string
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
      helm = object({
        helm_release = object({
          name       = string
          namespace  = string
          chart      = string
          version    = string
          repository = string
          values     = map(any)
        })
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
}
