# storage

This directory is responsible for providing cluster storage capabilities through Flux CD.

## What this component does

The storage layer enables dynamic provisioning of persistent volumes for workloads running in the cluster, using an NFS-backed StorageClass.

## What is deployed

The configuration in this folder provisions:

- a storage-related namespace for the provisioner
- a Helm repository source for the NFS provisioner chart
- an NFS subdirectory external provisioner deployment
- a default StorageClass configured to use the specified NFS server and share

## Files

- nfs/namespace.yaml: creates the namespace used by the provisioner
- nfs/repository.yaml: defines the Helm repository for the provisioner chart
- nfs/helm-release.yaml: installs the NFS dynamic provisioner with the cluster-specific NFS settings
- nfs/kustomization.yaml: composes the NFS provisioner resources for Flux

## Purpose in this infrastructure

This component gives the platform a reliable shared storage backend for persistent workloads, making PVC provisioning simpler and more consistent.
