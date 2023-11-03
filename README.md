# Infrastructure
## Requirements
- make
- Docker (https://docs.docker.com/engine/install/)
- Kind (https://kind.sigs.k8s.io/docs/user/quick-start/#installing-from-release-binaries)
- Fluxcd (https://fluxcd.io/flux/installation/#install-the-flux-cli)
- Kubectl (https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/#install-kubectl-binary-with-curl-on-linux)
- Helm (https://helm.sh/docs/intro/install/#from-script)
- Cilium CLI (https://docs.cilium.io/en/v1.14/gettingstarted/k8s-install-default/#install-the-cilium-cli)


(Ubuntu only) All requirements will be preinstalled by exporting the following environment variable:
```bash
export PREINSTALL_REQUIREMENTS=true
```

## Setup staging/development cluster using Kind
```bash
git checkout -b <branch-name>
export GITHUB_SSH_PRIVATE_KEY="${HOME}/.ssh/id_ed25519"
make bootstrap-kind
```
