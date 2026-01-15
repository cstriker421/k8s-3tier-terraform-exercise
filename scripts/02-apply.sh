terraform -chdir=terraform plan -var-file=terraform.tfvars -out=.plans/k8s.plan
terraform -chdir=terraform apply .plans/k8s.plan