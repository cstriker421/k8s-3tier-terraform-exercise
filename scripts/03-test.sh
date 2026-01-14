#!/usr/bin/env bash
set -euo pipefail

IP="$(minikube ip)"

retry() {
  local n=0
  local max=20
  local delay=2
  until "$@"; do
    n=$((n+1))
    if [ "$n" -ge "$max" ]; then
      echo "Command failed after $max attempts: $*"
      return 1
    fi
    sleep "$delay"
  done
}

echo "Testing Ingress at http://$IP ..."
echo

echo "1) Frontend HTML:"
retry curl -fsS "http://$IP/" | head -n 5
echo

echo "2) Backend health:"
retry curl -fsS "http://$IP/api/health"
echo
echo

echo "3) Backend message (increments DB counter):"
retry curl -fsS "http://$IP/api/message"
echo
echo

echo "✔️  All OK!"
