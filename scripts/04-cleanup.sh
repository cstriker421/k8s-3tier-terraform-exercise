#!/usr/bin/env bash
set -euo pipefail

NAMESPACE="${NAMESPACE:-k8s-3tier}"

kubectl delete ns "$NAMESPACE" --wait=true || true
echo "🗑️ Cleaned up namespace $NAMESPACE."
