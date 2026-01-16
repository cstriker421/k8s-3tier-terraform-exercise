#!/usr/bin/env bash
set -euo pipefail

# Ensures kubectl is usable
kubectl config current-context >/dev/null 2>&1 || {
  echo "ERROR: kubectl has no current context!"
  exit 1
}

# Ensures ingress controller exists
if ! kubectl get ns ingress-nginx >/dev/null 2>&1; then
  echo "WARNING: ingress-nginx namespace not found."
  echo "      Run 'make init' to enable ingress."
  exit 1
fi

# Terraform apply
TF_DIR="terraform"
PLAN_DIR="${TF_DIR}/.plans"
PLAN_FILE="${PLAN_DIR}/k8s.plan"
TFVARS="terraform.tfvars"

mkdir -p "${PLAN_DIR}"

terraform -chdir="${TF_DIR}" init
terraform -chdir="${TF_DIR}" plan -var-file="${TFVARS}" -out=".plans/$(basename "${PLAN_FILE}")"
terraform -chdir="${TF_DIR}" apply ".plans/$(basename "${PLAN_FILE}")"
