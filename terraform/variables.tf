variable "namespace" {
  description = "Kubernetes namespace for all resources"
  type        = string
  default     = "k8s-3tier"
}

variable "frontend_image" {
  description = "Frontend container image"
  type        = string
  default     = "k8s-3tier-frontend:1.0"
}

variable "backend_image" {
  description = "Backend container image"
  type        = string
  default     = "k8s-3tier-backend:1.0"
}

variable "frontend_replicas" {
  description = "Number of frontend replicas"
  type        = number
  default     = 2
}

variable "backend_replicas" {
  description = "Number of backend replicas"
  type        = number
  default     = 2
}

variable "db_name" {
  description = "Postgres database name"
  type        = string
  default     = "appdb"
}

variable "db_user" {
  description = "Postgres database user"
  type        = string
  default     = "appuser"
}

variable "db_password" {
  description = "Postgres database password (stored in a Secret)"
  type        = string
  sensitive   = true
}

variable "db_image" {
  description = "Postgres container image"
  type        = string
  default     = "postgres:16-alpine"
}

variable "db_storage" {
  description = "PVC size for Postgres data"
  type        = string
  default     = "1Gi"
}

variable "ingress_class_name" {
  description = "Ingress class name"
  type        = string
  default     = "nginx"
}

variable "app_message" {
  description = "Message exposed via backend ConfigMap"
  type        = string
  default     = "Hello from ConfigMap! Hope you're having a great day!"
}
