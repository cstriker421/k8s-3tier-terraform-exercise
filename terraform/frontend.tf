resource "kubernetes_service" "frontend" {
  metadata {
    name      = "frontend"
    namespace = kubernetes_namespace.this.metadata[0].name
  }

  spec {
    selector = {
      app = "frontend"
    }

    port {
      port        = 80
      target_port = 80
    }
  }
}

resource "kubernetes_deployment" "frontend" {
  metadata {
    name      = "frontend"
    namespace = kubernetes_namespace.this.metadata[0].name
    labels = {
      app = "frontend"
    }
  }

  spec {
    replicas = var.frontend_replicas

    selector {
      match_labels = {
        app = "frontend"
      }
    }

    template {
      metadata {
        labels = {
          app = "frontend"
        }
      }

      spec {
        container {
          name  = "frontend"
          image = var.frontend_image

          port {
            container_port = 80
          }
        }
      }
    }
  }
}
