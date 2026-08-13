# victoria-stack

This directory is responsible for deploying the VictoriaMetrics observability stack through Flux CD.

## What this component does

VictoriaMetrics provides monitoring and observability capabilities for logs, metrics, and traces. This stack is used to collect and store time-series telemetry from the platform.

## What is deployed

The configuration in this folder provisions:

- a dedicated Kubernetes namespace named victoria-metrics
- a Helm repository source for the VictoriaMetrics charts
- Helm releases for VictoriaLogs, VictoriaMetrics, and VictoriaTraces clusters

## Files

- namespace.yaml: creates the observability namespace
- repository.yaml: defines the Helm repository for VictoriaMetrics charts
- vm-logs-cluster.yaml: deploys the VictoriaLogs cluster
- vm-metrics-cluster.yaml: deploys the VictoriaMetrics cluster
- vm-traces-cluster.yaml: deploys the VictoriaTraces cluster
- kustomization.yaml: composes all of the resources for Flux to apply together

## Purpose in this infrastructure

This component provides the core observability backend for collecting, storing, and querying logs, metrics, and traces across the environment.
