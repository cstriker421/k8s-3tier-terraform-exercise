# Kubernetes 3-Tier Application Exercise

This repository contains a simple **3-tier application** deployed on a **local Kubernetes cluster using Minikube**.

The application demonstrates the core Kubernetes concepts covered in the module
with a strong emphasis on **automation and reproducibility**.

## Key concepts Demonstrated

- Deployments and horizontal scaling
- Services and internal service discovery
- ConfigMaps and Secrets
- Persistent storage using PVCs
- StatefulSets for databases
- Ingress for external access
- Automation using shell scripts and Makefile

## Application Overview

The application consists of three layers:

1. Frontend  
   - Nginx serving a static HTML page  
   - Accessible externally via Kubernetes Ingress
   - Communicates with the backend using `/api/*` endpoints

2. Backend  
   - Node.js + Express REST API  
   - Configuration provided via a ConfigMap 
   - Database credentials provided via a Secret  
   - Connects to PostgreSQL and increments a counter on each request

3. Database  
   - PostgreSQL  
   - Deployed as a StatefulSet  
   - Uses a PersistentVolumeClaim for persistent data storage

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
- GNU Make
- Bash-compatible shell

## Repository Structure

```
k8s-3tier-app-exercise/
├── README.md
├── namespace.yaml
├── frontend/
│   ├── app/
│   │   ├── index.html
│   │   └── Dockerfile
│   ├── deployment.yaml
│   └── service.yaml
├── backend/
│   ├── app/
│   │   ├── app.js
│   │   ├── package.json
│   │   └── Dockerfile
│   ├── deployment.yaml
│   ├── service.yaml
│   └── configmap.yaml
├── database/
│   ├── pvc.yaml
│   ├── secret.yaml
│   ├── statefulset.yaml
│   └── service.yaml
├── ingress/
│   └── ingress.yaml
├── scripts/
│   ├── 01-install.sh
│   ├── 02-deploy.sh
│   ├── 03-test.sh
│   └── 04-cleanup.sh
└── Makefile
```

## How to Run (Reccomended: Makefile)
> **All operational steps are automated.**
> No manual Docker or kubectl commands are required.

### 1. Start the cluster and prepare the environment

`make install`

This will:
- Start Minikube (using Docker driver if available)
- Enable the nginx ingress controller
- Create the Kubernetes namespace

### 2. Build images and deploy the application

`make deploy`

This will:
- Build frontend and backend images directly inside Minikube
- Deploy all Kubernetes resources in the correct dependency order
- Wait for workloads to become ready

### 3. Test the deployment

`make test`

This will:
- Build frontend and backend images directly inside Minikube
- Deploy all Kubernetes resources in the correct dependency order
- Wait for workloads to become ready

### 4. View deployment status

`make status`

This shows:
- BPds, Services, Ingress
- ConfigMaps, Secrets
- StatefulSets and PVCs

### 5. Scale the backend

`make scale N=3`

This demonstrates horizontal scaling of the backend Deployment (by three replicas in this example).

### 6. Cleanup

`make cleanup`

Deletes the application namespace and all associated resources.

## Kubernetes Objects Used

- **Deployments** (frontend, backend)
- **StatefulSet** (PostgreSQL)
- **Services** (ClusterIP)
- **ConfigMap**
- **Secret**
- **PersistentVolumeClaim**
- **Ingress**

## Design Notes

- The system is fully automated to reflect an infrastructure/architecture workflow.
- Images builds are handled inside the cluster runtime to avoid environment drift.
- The application is portable across environments that support Minikube.
- All configuration and secrets are externalized using Kubernetes-native mechanisms.

## Educational Context

This project was developed as part of a Kubernetes module to demonstrate:
- Correct use of Kubernetes primitives
- Clean repository structure.
- Automation best practices
- End-to-end application deployment

## Thank you!