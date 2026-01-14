SHELL := /bin/bash
NAMESPACE ?= k8s-3tier

.PHONY: help chmod install deploy test status scale cleanup reset

help:
	@echo "Targets:"
	@echo "  make install   - Starts minikube, enables ingress, and creates namespace."
	@echo "  make deploy    - Builds images and applies manifests."
	@echo "  make test      - Curls end-to-end tests."
	@echo "  make status    - Shows key resources."
	@echo "  make scale N=3 - Scales backend deployment to N replicas."
	@echo "  make cleanup   - Deletes the namespace"
	@echo "  make reset     - Performs cleanup and deletes Minikube."

chmod:
	chmod +x scripts/*.sh

install: chmod
	NAMESPACE=$(NAMESPACE) ./scripts/01-install.sh

deploy: chmod
	NAMESPACE=$(NAMESPACE) ./scripts/02-deploy.sh

test: chmod
	./scripts/03-test.sh

status:
	kubectl -n $(NAMESPACE) get deploy,rs,svc
	kubectl -n $(NAMESPACE) get statefulset,pvc
	kubectl -n $(NAMESPACE) get cm,secret
	kubectl -n $(NAMESPACE) get ingress

scale:
	@if [ -z "$(N)" ]; then echo "Usage: make scale N=3"; exit 1; fi
	kubectl -n $(NAMESPACE) scale deploy/backend --replicas=$(N)
	kubectl -n $(NAMESPACE) rollout status deploy/backend --timeout=300s

cleanup: chmod
	NAMESPACE=$(NAMESPACE) ./scripts/04-cleanup.sh

reset: cleanup
	minikube delete || true
