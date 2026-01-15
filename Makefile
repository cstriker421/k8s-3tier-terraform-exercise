TF_DIR := terraform
PLAN_DIR := $(TF_DIR)/.plans
PLAN := $(PLAN_DIR)/k8s.plan
TFVARS ?= terraform.tfvars

.PHONY: help init plan apply test destroy fmt validate clean

help:
	@echo "Targets:"
	@echo "  make init                 - Terraform init"
	@echo "  make plan TFVARS=dev.tfvars      - Terraform plan to $(PLAN)"
	@echo "  make apply TFVARS=dev.tfvars     - Apply saved plan"
	@echo "  make test                 - Run smoke tests"
	@echo "  make destroy TFVARS=dev.tfvars   - Destroy resources"
	@echo "  make fmt                  - Terraform fmt"
	@echo "  make validate             - Terraform validate"
	@echo "  make clean                - Remove plan artifacts"

init:
	@mkdir -p $(PLAN_DIR)
	terraform -chdir=$(TF_DIR) init

plan: init
	@mkdir -p $(PLAN_DIR)
	terraform -chdir=$(TF_DIR) plan -var-file=$(TFVARS) -out=.plans/$(notdir $(PLAN))

apply: plan
	terraform -chdir=$(TF_DIR) apply .plans/$(notdir $(PLAN))

test:
	./scripts/03-test.sh

destroy: init
	terraform -chdir=$(TF_DIR) destroy -var-file=$(TFVARS)

fmt:
	terraform -chdir=$(TF_DIR) fmt -recursive

validate: init
	terraform -chdir=$(TF_DIR) validate

clean:
	rm -rf $(PLAN_DIR)
