#!/usr/bin/env bash
set -euo pipefail

echo "==> Ensuring Minikube is running..."
if ! minikube status >/dev/null 2>&1; then
  minikube start
fi

echo "==> Using minikube kube context..."
kubectl config use-context minikube >/dev/null 2>&1 || true

echo "==> Ensuring ingress addon is enabled..."
minikube addons enable ingress >/dev/null 2>&1 || true

echo "==> Initialising Terraform..."
terraform -chdir=terraform init

echo "==> Init complete!"
