# dragonfly

This directory is responsible for deploying Dragonfly OSS through Flux CD.

## What this component does

Dragonfly is an open-source distributed P2P system designed to accelerate container image distribution and improve pull efficiency in large-scale Kubernetes environments. It helps reduce registry load and speeds up image pulls by sharing layers between nodes.

## What is deployed

The configuration in this folder provisions:

- a dedicated Kubernetes namespace named dragonfly-system
- a Helm repository source for the Dragonfly chart
- a Helm release for the Dragonfly deployment
- scheduler, client, and seed client settings with metrics enabled

## Files

- namespace.yaml: creates the Dragonfly namespace
- repository.yaml: defines the Helm repository for Dragonfly charts
- helm-release.yaml: installs the Dragonfly release with the required image and metrics configuration
- kustomization.yaml: composes the resources for Flux to apply together

## Purpose in this infrastructure

This component provides a P2P-based container image distribution layer that improves image pull performance and reduces pressure on the container registry.
