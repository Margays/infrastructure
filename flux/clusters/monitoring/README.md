# Monitoring cluster dependencies

This directory defines the Flux Kustomizations for the monitoring cluster.
The arrows below point from a dependency to the Kustomization that depends on
it. Flux waits for a dependency to become ready before reconciling the next
Kustomization.

```mermaid
graph TD
    cert_manager_controller[cert-manager-controller]
    metrics_server[metrics-server]
    external_secrets_controller[external-secrets-controller]
    external_secrets_config[external-secrets-config]
    storage[storage]
    cert_manager_config[cert-manager-config]
    dragonfly[dragonfly]
    victoria_stack[victoria-stack]
    prometheus_stack[prometheus-stack]
    apps[apps]

    cert_manager_controller --> metrics_server
    external_secrets_controller --> external_secrets_config
    external_secrets_config --> storage
    external_secrets_config --> cert_manager_config
    cert_manager_controller --> cert_manager_config
    storage --> dragonfly
    cert_manager_config --> victoria_stack
    dragonfly --> victoria_stack
    victoria_stack --> prometheus_stack
    cert_manager_config --> prometheus_stack
    victoria_stack --> apps
```

## Kustomization sources

| Kustomization | Path |
| --- | --- |
| `cert-manager-controller` | `flux/infrastructure/cert-manager/controller/overlays` |
| `metrics-server` | `flux/infrastructure/metrics-server/overlays` |
| `external-secrets-controller` | `flux/infrastructure/external-secrets/controller/overlays` |
| `external-secrets-config` | `flux/infrastructure/external-secrets/config/overlays/monitoring` |
| `storage` | `flux/infrastructure/storage/overlays/monitoring` |
| `cert-manager-config` | `flux/infrastructure/cert-manager/config/overlays` |
| `dragonfly` | `flux/infrastructure/dragonfly/overlays` |
| `victoria-stack` | `flux/infrastructure/victoria-stack/overlays` |
| `prometheus-stack` | `flux/infrastructure/prometheus/overlays/monitoring` |
| `apps` | `flux/apps/monitoring` |

The monitoring cluster loads these definitions from `infrastructure.yaml` and
`apps.yaml` through `kustomization.yaml`.
