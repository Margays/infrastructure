# cert-manager

This directory is responsible for deploying and managing cert-manager in the cluster through Flux CD.

## What this component does

cert-manager automates the issuance, renewal, and management of TLS certificates for Kubernetes workloads. It is commonly used together with ingress controllers and other services that require HTTPS certificates.

## What is deployed

The configuration in this folder provisions:

- a dedicated Kubernetes namespace named cert-manager
- a Helm repository source for the Jetstack charts
- the cert-manager Helm release from the Jetstack repository
- CRDs required by cert-manager, enabled as part of the Helm release

## Files

- namespace.yaml: creates the cert-manager namespace
- repository.yaml: defines the Helm repository for cert-manager charts
- helm-release.yaml: installs cert-manager with the desired chart version and settings
- kustomization.yaml: composes the resources for Flux to apply together

## Purpose in this infrastructure

This component provides the certificate lifecycle management foundation needed for secure TLS termination and automated certificate rotation across the platform.
