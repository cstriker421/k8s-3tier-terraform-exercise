#!/usr/bin/env bash
set -euo pipefail

# Config (override via env)
NAMESPACE="${NAMESPACE:-k8s-3tier}"
FRONTEND_SVC="${FRONTEND_SVC:-frontend}"
BACKEND_SVC="${BACKEND_SVC:-backend}"
DB_APP_LABEL="${DB_APP_LABEL:-app=postgres}"
BACKEND_APP_LABEL="${BACKEND_APP_LABEL:-app=backend}"
FRONTEND_APP_LABEL="${FRONTEND_APP_LABEL:-app=frontend}"

BACKEND_HEALTH_PATH="${BACKEND_HEALTH_PATH:-/api/health}"
FRONTEND_PATH="${FRONTEND_PATH:-/}"

# If Ingress uses a hostname, sets INGRESS_HOST (e.g. "app.local")
INGRESS_HOST="${INGRESS_HOST:-}"

echo "==> Testing deployment in namespace: ${NAMESPACE}"

# Pre-checks (avoids kubectl defaulting to localhost:8080)
if ! kubectl config current-context >/dev/null 2>&1; then
  echo "No kubectl context set; trying to use 'minikube'"
  kubectl config use-context minikube >/dev/null
fi

command -v kubectl >/dev/null 2>&1 || { echo "kubectl not found!"; exit 1; }
command -v curl >/dev/null 2>&1 || { echo "curl not found!"; exit 1; }

echo "==> Checking namespace exists"
kubectl get ns "${NAMESPACE}" >/dev/null

echo "==> Waiting for Postgres (StatefulSet/Pods) to be Ready..."
# Tries common names; tolerates differences
kubectl -n "${NAMESPACE}" rollout status statefulset/postgres --timeout=180s 2>/dev/null || true
kubectl -n "${NAMESPACE}" wait --for=condition=Ready pod -l "${DB_APP_LABEL}" --timeout=180s

echo "==> Waiting for Backend deployment to be Ready..."
kubectl -n "${NAMESPACE}" rollout status deployment/backend --timeout=180s
kubectl -n "${NAMESPACE}" wait --for=condition=Ready pod -l "${BACKEND_APP_LABEL}" --timeout=180s

echo "==> Waiting for Frontend deployment to be Ready..."
kubectl -n "${NAMESPACE}" rollout status deployment/frontend --timeout=180s
kubectl -n "${NAMESPACE}" wait --for=condition=Ready pod -l "${FRONTEND_APP_LABEL}" --timeout=180s

echo "==> Checking services exist"
kubectl -n "${NAMESPACE}" get svc "${FRONTEND_SVC}" >/dev/null
kubectl -n "${NAMESPACE}" get svc "${BACKEND_SVC}" >/dev/null

# Helper: curls with optional Host header
curl_check() {
  local url="$1"
  local label="$2"

  if [[ -n "${INGRESS_HOST}" ]]; then
    echo "==> ${label}: ${url} (Host: ${INGRESS_HOST})"
    curl -fsS -H "Host: ${INGRESS_HOST}" "${url}" >/dev/null
  else
    echo "==> ${label}: ${url}"
    curl -fsS "${url}" >/dev/null
  fi
}

# 1) Try Ingress (preferred)
echo "==> Attempting Ingress test (if present)"
if kubectl -n "${NAMESPACE}" get ingress >/dev/null 2>&1 && [[ "$(kubectl -n "${NAMESPACE}" get ingress -o name | wc -l | tr -d ' ')" -gt 0 ]]; then
  echo "    Ingress found."
  if command -v minikube >/dev/null 2>&1; then
    MINIKUBE_IP="$(minikube ip 2>/dev/null || true)"
  else
    MINIKUBE_IP=""
  fi

  if [[ -n "${MINIKUBE_IP}" ]]; then
    curl_check "http://${MINIKUBE_IP}${BACKEND_HEALTH_PATH}" "Backend health (ingress)"
    curl_check "http://${MINIKUBE_IP}${FRONTEND_PATH}" "Frontend (ingress)"
    echo "✅ Ingress test passed via minikube IP: ${MINIKUBE_IP}"
    exit 0
  else
    echo "    minikube IP unavailable; skipping ingress IP test."
  fi
else
  echo "    No Ingress found; will test via Service URLs."
fi

# 2) Fallback: minikube service --url
if command -v minikube >/dev/null 2>&1; then
  echo "==> Attempting Service URL test via 'minikube service --url'"

  BACKEND_URL="$(minikube service -n "${NAMESPACE}" "${BACKEND_SVC}" --url 2>/dev/null | head -n 1 || true)"
  FRONTEND_URL="$(minikube service -n "${NAMESPACE}" "${FRONTEND_SVC}" --url 2>/dev/null | head -n 1 || true)"

  if [[ -n "${BACKEND_URL}" ]]; then
    curl_check "${BACKEND_URL}${BACKEND_HEALTH_PATH}" "Backend health (service URL)"
  else
    echo "    Could not get backend service URL from minikube."
  fi

  if [[ -n "${FRONTEND_URL}" ]]; then
    curl_check "${FRONTEND_URL}${FRONTEND_PATH}" "Frontend (service URL)"
  else
    echo "    Could not get frontend service URL from minikube."
  fi

  if [[ -n "${BACKEND_URL}" && -n "${FRONTEND_URL}" ]]; then
    echo "✅ Service URL tests passed"
    exit 0
  fi
fi

# 3) Last resort: port-forward
echo "==> Fallback: port-forward tests"
TMPDIR="$(mktemp -d)"
cleanup() {
  if [[ -f "${TMPDIR}/pf.pid" ]]; then
    kill "$(cat "${TMPDIR}/pf.pid")" >/dev/null 2>&1 || true
  fi
  rm -rf "${TMPDIR}"
}
trap cleanup EXIT

echo "    Port-forwarding backend svc -> localhost:18080"
kubectl -n "${NAMESPACE}" port-forward svc/"${BACKEND_SVC}" 18080:80 >/dev/null 2>&1 &
echo $! > "${TMPDIR}/pf.pid"
sleep 2
curl_check "http://127.0.0.1:18080${BACKEND_HEALTH_PATH}" "Backend health (port-forward)"

# Restarts pf for frontend to avoid port clash
kill "$(cat "${TMPDIR}/pf.pid")" >/dev/null 2>&1 || true
sleep 1

echo "    Port-forwarding frontend svc -> localhost:18081"
kubectl -n "${NAMESPACE}" port-forward svc/"${FRONTEND_SVC}" 18081:80 >/dev/null 2>&1 &
echo $! > "${TMPDIR}/pf.pid"
sleep 2
curl_check "http://127.0.0.1:18081${FRONTEND_PATH}" "Frontend (port-forward)"

echo "✅ Port-forward tests passed"
