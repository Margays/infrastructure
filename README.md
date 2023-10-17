# Infrastructure
## Setup staging/development cluster using Kind
```bash
git checkout -b <branch-name>
make build-kind

export GITHUB_USERNAME="<username>"
export GITHUB_TOKEN="<personal access token>"
make flux
```
