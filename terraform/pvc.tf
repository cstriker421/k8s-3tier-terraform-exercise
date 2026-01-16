resource "kubernetes_persistent_volume_claim" "postgres" {
  metadata {
    name      = "postgres-pvc"
    namespace = kubernetes_namespace.this.metadata[0].name
  }

  spec {
    access_modes = ["ReadWriteOnce"]

    resources {
      requests = {
        storage = var.db_storage
      }
    }
  }
}
