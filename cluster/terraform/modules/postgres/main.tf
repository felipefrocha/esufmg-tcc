

resource "kubernetes_service_account" "postgres" {
  metadata {
    name = "postgres"
  }
  secret {
    name = element(kubernetes_secret.postgres.metadata.*.name, 0)
  }
}

resource "kubernetes_secret" "postgres" {
  metadata {
    name = "postgres-secret"
  }
  data = {
    "POSTGRES_PASSWORD" = "${var.postgres_secret}"
  }
  # type = "Opaque"
}

resource "kubernetes_persistent_volume_claim" "postgres" {
  metadata {
    name = "pvc-postgres"
  }
  spec {
    access_modes = ["ReadWriteOnce"]
    resources {
      requests = {
        storage = "10Gi"
      }
    }
    # volume_name = kubernetes_storage_class.nfs.metadata.name
    storage_class_name = var.storage_class_name
  }
}

resource "kubernetes_stateful_set" "postgres" {
  metadata {
    annotations = {
      Enviroment = "Prod"
    }

    labels = {
      app                               = "postgres"
      "kubernetes.io/cluster-service"   = "true"
      "addonmanager.kubernetes.io/mode" = "Reconcile"
    }

    name = "postgres"
  }

  spec {
    pod_management_policy  = "OrderedReady"
    replicas               = 1
    revision_history_limit = 5

    selector {
      match_labels = {
        app = "postgres"
      }
    }

    service_name = "postgres"

    template {
      metadata {
        labels = {
          app = "postgres"
        }
        annotations = {}
      }

      spec {
        service_account_name = "postgres"
        container {
          name              = "postgres"
          image             = "postgres:latest"
          image_pull_policy = "IfNotPresent"

          args = [

          ]

          port {
            container_port = 5432
            name           = "tcp-postgres"
          }

          resources {
            limits = {
              cpu    = "2000m"
              memory = "4Gi"
            }

            requests = {
              cpu    = "1000m"
              memory = "2Gi"
            }
          }
          env {
            name = "POSTGRES_PASSWORD"
            value_from {
              secret_key_ref {
                name     = element(kubernetes_secret.postgres.metadata.*.name, 0)
                key      = "POSTGRES_PASSWORD"
                optional = false
              }
            }
          }
          env {
            name  = "PGDATA"
            value = "/data"
          }

          volume_mount {
            name       = "postgres-data"
            mount_path = "/data"
            sub_path   = ""
          }

          readiness_probe {
            exec {
              command = [
                "bash",
                "-ec",
                "PGPASSWORD=$POSTGRES_PASSWORD psql -w -U \"postgres\" -d \"postgres\"  -h 127.0.0.1 -c \"SELECT 1\""
              ]
            }
            initial_delay_seconds = 5
            timeout_seconds       = 5
            period_seconds        = 10
            success_threshold     = 1
            failure_threshold     = 6
          }

          liveness_probe {
            exec {
              command = [
                "bash",
                "-ec",
                "PGPASSWORD=$POSTGRES_PASSWORD psql -w -U \"postgres\" -d \"postgres\"  -h 127.0.0.1 -c \"SELECT 1\""
              ]
            }
            initial_delay_seconds = 5
            timeout_seconds       = 5
            period_seconds        = 10
            success_threshold     = 1
            failure_threshold     = 6
          }
        }

        termination_grace_period_seconds = 300

        # volume {
        #   name = "config-volume"

        #   config_map {
        #     name = "prometheus-config"
        #   }
        # }
      }
    }

    update_strategy {
      type = "RollingUpdate"

      rolling_update {
        partition = 1
      }
    }

    volume_claim_template {
      metadata {
        name        = "postgres-data"
        annotations = {}
        labels      = {}
      }

      spec {
        access_modes       = ["ReadWriteOnce"]
        storage_class_name = "nfs-csi"

        resources {
          requests = {
            storage = "10Gi"
          }
        }
      }
    }
  }
  timeouts {
    create = "5m"
    update = "5m"
    delete = "5m"
  }
}

resource "kubernetes_service" "postgres" {
  metadata {
    name = "postgres"
  }
  spec {
    selector = {
      app = "postgres"
    }
    session_affinity = "ClientIP"
    port {
      port        = 5432
      target_port = "tcp-postgres"
      protocol    = "TCP"
    }

    type = "ClusterIP"
  }
}
