# Infrastructure
## Setup staging/development cluster using Kind
```bash
git checkout -b <branch-name>
export GITHUB_SSH_PRIVATE_KEY="${HOME}/.ssh/id_ed25519"
make bootstrap-kind
```
