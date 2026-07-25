# How to run
1. Create terraform.tfvars in dir with this README.md
```
project_name     = "orion"
proxmox_endpoint = "https://example.local:8006"
proxmox_username = "root@pam"
proxmox_password = "???"
```

2. (Optional - s3 backend) Create config.s3.tfbackend
```
endpoints = {
    s3 = "https://s3.local:30292"   # Minio endpoint
}
region = "main"                     # Region validation will be skipped
access_key = "???"
secret_key = "???"
bucket = "tfstate"                  # Name of the S3 bucket
key = "orion.tfstate"               # Name of the tfstate file

skip_credentials_validation = true  # Skip AWS related checks and validations
skip_requesting_account_id = true
skip_metadata_api_check = true
skip_region_validation = true
use_path_style = true               
```

3. Initialize terraform
```bash
terraform init -backend-config=./config.s3.tfbackend
```

4. Run terraform plan
```bash
terraform plan -out=out.plan
```

5. Apply plan
```bash
terraform apply out.plan
```

6. Get kubeconfig
```bash
terraform output kubeconfig
```
