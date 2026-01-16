resource "kubernetes_config_map" "backend" {
  metadata {
    name      = "backend-config"
    namespace = kubernetes_namespace.this.metadata[0].name
  }

  data = {
    DB_HOST     = "postgres"
    DB_PORT     = "5432"
    DB_NAME     = var.db_name
    DB_USER     = var.db_user
    APP_MESSAGE = var.app_message
  }
}

resource "kubernetes_service" "backend" {
  metadata {
    name      = "backend"
    namespace = kubernetes_namespace.this.metadata[0].name
  }

  spec {
    selector = {
      app = "backend"
    }

    port {
      port        = 80
      target_port = 3000
    }
  }
}

resource "kubernetes_deployment" "backend" {
  metadata {
    name      = "backend"
    namespace = kubernetes_namespace.this.metadata[0].name
    labels = {
      app = "backend"
    }
  }

  spec {
    replicas = var.backend_replicas

    selector {
      match_labels = {
        app = "backend"
      }
    }

    template {
      metadata {
        labels = {
          app = "backend"
        }
      }

      spec {
        container {
          name  = "backend"
          image = var.backend_image

          port {
            container_port = 3000
          }

          env_from {
            config_map_ref {
              name = kubernetes_config_map.backend.metadata[0].name
            }
          }

          env {
            name = "DB_PASSWORD"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.postgres.metadata[0].name
                key  = "POSTGRES_PASSWORD"
              }
            }
          }

          readiness_probe {
            http_get {
              path = "/api/health"
              port = 3000
            }
            initial_delay_seconds = 5
            period_seconds        = 5
          }
        }
      }
    }
  }

  depends_on = [kubernetes_stateful_set.postgres]
}
