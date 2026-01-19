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
INGRESS_HOST="${INGRESS_HOST:-}"

echo "==> Testing deployment in namespace: ${NAMESPACE}..."

command -v kubectl >/dev/null 2>&1 || { echo "kubectl not found!"; exit 1; }
command -v curl >/dev/null 2>&1 || { echo "curl not found!"; exit 1; }

kubectl config current-context >/dev/null 2>&1 || kubectl config use-context minikube >/dev/null 2>&1 || true

echo "==> Checking namespace exists..."
kubectl get ns "${NAMESPACE}" >/dev/null

echo "==> Waiting for Postgres (StatefulSet/Pods) to be ready..."
kubectl -n "${NAMESPACE}" rollout status statefulset/postgres --timeout=180s 2>/dev/null || true
kubectl -n "${NAMESPACE}" wait --for=condition=Ready pod -l "${DB_APP_LABEL}" --timeout=180s

echo "==> Verifying Postgres accepts connections..."
PGPASSWORD="$(kubectl -n "${NAMESPACE}" get secret postgres-secret -o jsonpath='{.data.POSTGRES_PASSWORD}' | base64 -d)"
PGUSER="$(kubectl -n "${NAMESPACE}" get secret postgres-secret -o jsonpath='{.data.POSTGRES_USER}' | base64 -d)"
PGDB="$(kubectl -n "${NAMESPACE}" get secret postgres-secret -o jsonpath='{.data.POSTGRES_DB}' | base64 -d)"

kubectl -n "${NAMESPACE}" exec statefulset/postgres -c postgres -- sh -lc \
  "PGPASSWORD='${PGPASSWORD}' psql -U '${PGUSER}' -d '${PGDB}' -c 'SELECT 1;' >/dev/null"

echo "OK: Postgres connectivity check passed."

echo "==> Waiting for Backend deployment to be ready..."
kubectl -n "${NAMESPACE}" rollout status deployment/backend --timeout=180s
kubectl -n "${NAMESPACE}" wait --for=condition=Ready pod -l "${BACKEND_APP_LABEL}" --timeout=180s

echo "==> Waiting for Frontend deployment to be ready..."
kubectl -n "${NAMESPACE}" rollout status deployment/frontend --timeout=180s
kubectl -n "${NAMESPACE}" wait --for=condition=Ready pod -l "${FRONTEND_APP_LABEL}" --timeout=180s

echo "==> Checking services exist..."
kubectl -n "${NAMESPACE}" get svc "${FRONTEND_SVC}" >/dev/null
kubectl -n "${NAMESPACE}" get svc "${BACKEND_SVC}" >/dev/null

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

echo "==> Attempting Ingress test (if present)..."
if kubectl get ns ingress-nginx >/dev/null 2>&1 && kubectl -n "${NAMESPACE}" get ingress >/dev/null 2>&1; then
  echo "    Ingress found."
  MINIKUBE_IP=""
  if command -v minikube >/dev/null 2>&1; then
    MINIKUBE_IP="$(minikube ip 2>/dev/null || true)"
  fi

  if [[ -n "${MINIKUBE_IP}" ]]; then
    curl_check "http://${MINIKUBE_IP}${BACKEND_HEALTH_PATH}" "Backend health (ingress)"
    curl_check "http://${MINIKUBE_IP}/api/message" "Backend message (ingress)"  
    curl_check "http://${MINIKUBE_IP}${FRONTEND_PATH}" "Frontend (ingress)"
    echo "OK: ingress reachable via minikube IP."
    exit 0
  else
    echo "WARNING: minikube IP unavailable; skipping ingress IP test."
  fi
else
  echo "WARNING: ingress controller or ingress resource not present; skipping ingress test."
fi

echo "==> Fallback: port-forward service tests..."
tmpdir="$(mktemp -d)"
cleanup() {
  if [[ -f "${tmpdir}/pf.pid" ]]; then
    kill "$(cat "${tmpdir}/pf.pid")" >/dev/null 2>&1 || true
  fi
  rm -rf "${tmpdir}"
}
trap cleanup EXIT

kubectl -n "${NAMESPACE}" port-forward svc/"${BACKEND_SVC}" 18080:80 >/dev/null 2>&1 &
echo $! > "${tmpdir}/pf.pid"
sleep 2
curl_check "http://127.0.0.1:18080${BACKEND_HEALTH_PATH}" "Backend health (port-forward)"

kill "$(cat "${tmpdir}/pf.pid")" >/dev/null 2>&1 || true
sleep 1

kubectl -n "${NAMESPACE}" port-forward svc/"${FRONTEND_SVC}" 18081:80 >/dev/null 2>&1 &
echo $! > "${tmpdir}/pf.pid"
sleep 2
curl_check "http://127.0.0.1:18081${FRONTEND_PATH}" "Frontend (port-forward)"

echo "OK: tests passed!"
