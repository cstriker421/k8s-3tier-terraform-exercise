resource "kubernetes_secret" "postgres" {
  metadata {
    name      = "postgres-secret"
    namespace = kubernetes_namespace.this.metadata[0].name
  }

  type = "Opaque"

  data = {
    POSTGRES_DB       = var.db_name
    POSTGRES_USER     = var.db_user
    POSTGRES_PASSWORD = var.db_password
  }
}

resource "kubernetes_service" "postgres" {
  metadata {
    name      = "postgres"
    namespace = kubernetes_namespace.this.metadata[0].name
  }

  spec {
    selector = {
      app = "postgres"
    }

    port {
      name        = "postgres"
      port        = 5432
      target_port = 5432
    }
  }
}

resource "kubernetes_stateful_set" "postgres" {
  metadata {
    name      = "postgres"
    namespace = kubernetes_namespace.this.metadata[0].name
    labels = {
      app = "postgres"
    }
  }

  spec {
    service_name = kubernetes_service.postgres.metadata[0].name
    replicas     = 1

    selector {
      match_labels = {
        app = "postgres"
      }
    }

    template {
      metadata {
        labels = {
          app = "postgres"
        }
      }

      spec {
        container {
          name  = "postgres"
          image = var.db_image

          port {
            container_port = 5432
          }

          readiness_probe {
            tcp_socket {
                port = 5432
            }
            initial_delay_seconds = 5
            period_seconds        = 5
          } 

          env {
            name = "POSTGRES_DB"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.postgres.metadata[0].name
                key  = "POSTGRES_DB"
              }
            }
          }

          env {
            name = "POSTGRES_USER"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.postgres.metadata[0].name
                key  = "POSTGRES_USER"
              }
            }
          }

          env {
            name = "POSTGRES_PASSWORD"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.postgres.metadata[0].name
                key  = "POSTGRES_PASSWORD"
              }
            }
          }

          volume_mount {
            name       = "data"
            mount_path = "/var/lib/postgresql/data"
          }
        }

        volume {
          name = "data"
          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim.postgres.metadata[0].name
          }
        }
      }
    }
  }
}
