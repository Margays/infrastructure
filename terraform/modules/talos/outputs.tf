output "name" {
  value = tostring(var.configuration.spec.name)
  type  = string
}

output "api_endpoint" {
  value = tostring(var.configuration.spec.cluster.endpoint)
  type  = string
}

output "kubeconfig" {
  value     = talos_cluster_kubeconfig.this
  sensitive = true
}

output "talosconfig" {
  value     = data.talos_client_configuration.this.talos_config
  sensitive = true
}
