# Kubernetes 3-Tier Application Exercise — Terraform Edition

This repository recreates the **Kubernetes 3-tier application** from the previous exercise,
but **fully managed using Terraform** instead of raw Kubernetes YAML manifests.

The goal of this exercise is to demonstrate:
- Correct use of the **Terraform Kubernetes provider**
- Infrastructure-as-code principles
- Clean modular structure
- Fully automated deployment, testing, and teardown

## Relationship to the Previous Exercise

This project is a **direct evolution** of the earlier Kubernetes 3-tier application.

### Reused
- Most of the same application architecture (frontend, backend, database)
- Same containerized applications
- Same Kubernetes concepts (Deployments, Services, Secrets, PVCs, Ingress)

### Different
- **All Kubernetes resources are now defined using Terraform**
- No `kubectl apply -f` is used for application resources
- Deployment lifecycle is managed via:
  - `terraform plan`
  - `terraform apply`
  - `terraform destroy`
- Improved automation using shell scripts and Makefile

Legacy Kubernetes YAML files from the previous exercise have been removed.

## Application Overview

The application consists of three layers:

### 1. Frontend
- Nginx serving a static HTML page
- Deployed as a Kubernetes Deployment
- Exposed externally via Kubernetes Ingress

### 2. Backend
- Node.js + Express REST API
- Configuration provided via a ConfigMap
- Database credentials provided via a Secret
- Connects to PostgreSQL using internal service discovery

### 3. Database
- PostgreSQL
- Deployed as a StatefulSet
- Uses a PersistentVolumeClaim for persistent storage

## Architecture Diagram

```
User Browser  
     |  
     v  
Ingress (nginx)  
     |  
     +--> Frontend Service --> Frontend Pods  
     |  
     +--> Backend Service --> Backend Pods --> PostgreSQL StatefulSet --> PVC  
```

## Prerequisites

- Docker (Docker Desktop recommended)
- Minikube
- kubectl
- Terraform
- GNU Make
- Bash-compatible shell

## Repository Structure

```
k8s-3tier-app-exercise/
├── README.md
├── app/
│   ├── backend/
│   │   ├── Dockerfile
│   │   ├── app.js
│   │   └── package.json
│   └── frontend/
│       ├── Dockerfile
│       └── index.html
├── terraform/
│   ├── providers.tf
│   ├── namespace.tf
│   ├── pvc.tf
│   ├── database.tf
│   ├── backend.tf
│   ├── frontend.tf
│   ├── ingress.tf
│   ├── variables.tf
│   ├── terraform.tfvars
│   └── dev.tfvars
├── scripts/
│   ├── 01-install.sh
│   ├── 02-apply.sh
│   ├── 03-test.sh
│   └── 04-destroy.sh
└── Makefile
```

## How to Run (Reccomended: Makefile)
> **All operational steps are automated.**
> No manual Docker or kubectl commands are required.

### 1. Start the cluster and prepare the environment

`make init`

This will:
- Start Minikube if not running (using Docker driver if available)
- Set the Kubernetes context
- Enable the ingress controller
- Run `terraform init`

### 2. Deploy infrastructure and application

`make apply`

This will:
- Build frontend and backend images directly inside Minikube
- Generate a Terraform execution plan
- Apply all Kubernetes resources
- Wait for workloads to become ready

### 3. Test the deployment

`make test`

This will:
- Verify namespace and workloads
- Confirm PostgreSQL readiness
- Validate backend and frontend via Ingress
- Confirm `/api/health` and `/api/message` endpoints

### 4. Destroy the environment

`make destroy`

This will:
- Destroy all Terraform-managed Kubernetes resources

## Kubernetes Objects Managed via Terraform

- Namespace
- Deployments (frontend, backend)
- StatefulSet (PostgreSQL)
- Services
- ConfigMaps
- Secrets
- PersistentVolumeClaims
- Ingress

## Known Limitations
- Designed for local development using Minikube
- Images are built locally and loaded into Minikube
- Not intended for production or multi-node clusters

## Educational Context

This project was developed as part of a Kubernetes and module to demonstrate:
- Transition from imperative Kubernetes YAML to declarative Terraform
- Clean, modular infrastructure design
- End-to-end automated application deployment

## Thank you!