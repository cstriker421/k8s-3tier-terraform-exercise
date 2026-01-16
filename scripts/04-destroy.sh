#!/usr/bin/env bash
set -euo pipefail
terraform -chdir=terraform destroy -var-file=terraform.tfvars
echo "==> Destroy complete!"