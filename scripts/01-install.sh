#!/usr/bin/env bash
set -euo pipefail

NAMESPACE="${NAMESPACE:-k8s-3tier}"

#Starts Minikube even if not running
if command -v docker >/dev/null 2>&1 && docker info >/dev/null 2>&1; 
    then
        minikube start --driver=docker
        echo "Starting Minikube..."
    else
        minikube start
        echo "Starting Minikube..."
    fi

# Enables ingress
minikube addons enable ingress || true

# Waits for ingress controller (helps avoid flaky first deploy)
echo "🕒  Waiting for ingress controller (up to 30s)..."

kubectl wait -n ingress-nginx \
    --for=condition=Ready pod \
    -l app.kubernetes.io/name=ingress-nginx \
    --timeout=30s || true

# Creates namespace
kubectl get ns "$NAMESPACE" >/dev/null 2>&1 || kubectl create ns "$NAMESPACE"

echo "🖥️  Minikube is ready."
kubectl get nodes
kubectl get pods -n ingress-nginx || true
