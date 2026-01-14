#!/usr/bin/env bash
set -euo pipefail

NAMESPACE="${NAMESPACE:-k8s-3tier}"

kubectl get ns "$NAMESPACE" >/dev/null 2>&1 || kubectl create ns "$NAMESPACE"

# Builds images inside the cluster runtime
minikube image build -t k8s-3tier-frontend:1.0 ./frontend/app
minikube image build -t k8s-3tier-backend:1.0 ./backend/app

# Applies in dependency order
kubectl apply -n "$NAMESPACE" -f database/secret.yaml
kubectl apply -n "$NAMESPACE" -f database/pvc.yaml
kubectl apply -n "$NAMESPACE" -f database/service.yaml
kubectl apply -n "$NAMESPACE" -f database/statefulset.yaml

kubectl apply -n "$NAMESPACE" -f backend/configmap.yaml
kubectl apply -n "$NAMESPACE" -f backend/deployment.yaml
kubectl apply -n "$NAMESPACE" -f backend/service.yaml

kubectl apply -n "$NAMESPACE" -f frontend/deployment.yaml
kubectl apply -n "$NAMESPACE" -f frontend/service.yaml

kubectl apply -n "$NAMESPACE" -f ingress/ingress.yaml

# Waits for readiness
kubectl rollout status -n "$NAMESPACE" statefulset/postgres --timeout=60s
kubectl rollout status -n "$NAMESPACE" deployment/backend --timeout=60s
kubectl rollout status -n "$NAMESPACE" deployment/frontend --timeout=60s

echo
echo "📨  Deployed. Try:"
echo "📋  http://$(minikube ip)/ and http://$(minikube ip)/api/health via 'make test'"