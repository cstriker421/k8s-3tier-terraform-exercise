resource "kubernetes_ingress_v1" "app" {
  metadata {
    name      = "app-ingress"
    namespace = kubernetes_namespace.this.metadata[0].name
  }

  spec {
    ingress_class_name = var.ingress_class_name

    rule {
      http {
        path {
          path      = "/api"
          path_type = "Prefix"

          backend {
            service {
              name = kubernetes_service.backend.metadata[0].name
              port { number = 80 }
            }
          }
        }

        path {
          path      = "/"
          path_type = "Prefix"

          backend {
            service {
              name = kubernetes_service.frontend.metadata[0].name
              port { number = 80 }
            }
          }
        }
      }
    }
  }
}
