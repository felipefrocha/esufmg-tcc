resource "kubernetes_config_map_v1" "prometheus" {
  metadata {
    name = "prometheus-config"
  }

  data = {
    "prometheus.yaml" = "${file("${path.module}/data/config.yaml")}"
  }
}

resource "kubernetes_cluster_role_v1" "prometheus_server" {
  metadata {
    name = "prometheus-server"
  }
  rule {
    api_groups = [""]
    resources = [
      "nodes",
      "nodes/proxy",
      "services",
      "endpoints",
      "pods"
    ]
    verbs = [
      "get",
      "list",
      "watch"
    ]
  }
  rule {
    api_groups = ["extensions"]
    resources  = ["ingresses"]
    verbs = [
      "get",
      "list",
      "watch"
    ]
  }
}

resource "kubernetes_cluster_role_binding_v1" "prometheus_server" {
  metadata {
    name = "prometheus-server"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = element(kubernetes_cluster_role_v1.prometheus_server.metadata.*.name, 0)
  }
  subject {
    kind = "ServiceAccount"
    name = "prometheus-server"
    namespace = "default"
  }

  subject {
    kind = "ServiceAccount"
    name = "prometheus-server"
    namespace = "ingress-nginx"
  }
}

resource "kubernetes_manifest" "service_account_prometheus" {
  manifest = {
    apiVersion = "v1"
    kind       = "ServiceAccount"
    metadata = {
      namespace = "default"
      name      = "prometheus-server"
    }

    automountServiceAccountToken = true
    
  }
}

resource "kubernetes_manifest" "service_account_prometheus_ingress" {
  manifest = {
    apiVersion = "v1"
    kind       = "ServiceAccount"
    metadata = {
      namespace = "ingress-nginx"
      name      = "prometheus-server"
    }

    automountServiceAccountToken = true
    
  }
}


resource "kubernetes_stateful_set_v1" "prometheus" {
  metadata {
    annotations = {

    }

    labels = {
      app                               = "prometheus"
      "kubernetes.io/cluster-service"   = "true"
      "addonmanager.kubernetes.io/mode" = "Reconcile"
      version                           = "v2.2.1"
    }

    name = "prometheus"
  }

  spec {
    pod_management_policy  = "Parallel"
    replicas               = 1
    revision_history_limit = 5

    selector {
      match_labels = {
        app = "prometheus"
      }
    }

    service_name = "prometheus"

    template {
      metadata {
        labels = {
          app = "prometheus"
        }

        annotations = {}
      }

      spec {
        service_account_name = "prometheus"

        init_container {
          name              = "init-chown-data"
          image             = "busybox:latest"
          image_pull_policy = "IfNotPresent"
          command           = ["chown", "-R", "65534:65534", "/data"]

          volume_mount {
            name       = "prometheus-data"
            mount_path = "/data"
            sub_path   = ""
          }
        }

        container {
          name              = "prometheus-server-configmap-reload"
          image             = "jimmidyson/configmap-reload:v0.1"
          image_pull_policy = "IfNotPresent"

          args = [
            "--volume-dir=/etc/config",
            "--webhook-url=http://localhost:9090/-/reload",
          ]

          volume_mount {
            name       = "config-volume"
            mount_path = "/etc/config"
            read_only  = true
          }

          resources {
            limits = {
              cpu    = "10m"
              memory = "10Mi"
            }

            requests = {
              cpu    = "10m"
              memory = "10Mi"
            }
          }
        }

        container {
          name              = "prometheus-server"
          image             = "prom/prometheus:v2.2.1"
          image_pull_policy = "IfNotPresent"

          args = [
            "--config.file=/etc/config/prometheus.yaml",
            "--storage.tsdb.path=/data",
            "--web.console.libraries=/etc/prometheus/console_libraries",
            "--web.console.templates=/etc/prometheus/consoles",
            "--web.enable-lifecycle",
          ]

          port {
            container_port = 9090
          }

          resources {
            limits = {
              cpu    = "200m"
              memory = "1000Mi"
            }

            requests = {
              cpu    = "200m"
              memory = "1000Mi"
            }
          }

          volume_mount {
            name       = "config-volume"
            mount_path = "/etc/config/"
          }

          volume_mount {
            name       = "prometheus-data"
            mount_path = "/data"
            sub_path   = ""
          }

          readiness_probe {
            http_get {
              path = "/-/ready"
              port = 9090
            }
            failure_threshold = 6
            period_seconds = 10
            success_threshold = 1
            initial_delay_seconds = 30
            timeout_seconds       = 30
          }

          liveness_probe {
            http_get {
              path   = "/-/healthy"
              port   = 9090
              scheme = "HTTP"
            }
            failure_threshold = 6
            period_seconds = 10
            success_threshold = 1
            initial_delay_seconds = 30
            timeout_seconds       = 30
          }
        }

        termination_grace_period_seconds = 300

        volume {
          name = "config-volume"
          config_map {
            name         = "prometheus-config"
            default_mode = "0444"
          }
        }
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
        name = "prometheus-data"
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
    create = "3m"
    update = "3m"
    delete = "3m"
  }
}

resource "kubernetes_service_v1" "prometheus" {
  metadata {
    name = "prometheus"
  }
  spec {
    selector = {
      app = "prometheus"
    }
    session_affinity = "ClientIP"
    port {
      port        = 9090
      target_port = 9090
    }

    type = "ClusterIP"
  }
}


resource "kubernetes_ingress_v1" "prometheus" {
  metadata {
    name = "prometheus-ingress"
    annotations =  {
      "nginx.ingress.kubernetes.io/rewrite-target" = "/$1"
    }
  }

  spec {
    ingress_class_name = "nginx"
    rule {
      host = "prometheus.local"
      http {
        path {
          backend {
            service {
              name = "prometheus"
              port {
                number = 9090
              }
            }
          }
          path = "/"
        }
      }
    }

    rule {
      http {
        path {
          path_type = "Prefix"
          path      = "/prometheus/?(.*)"
          backend {
            service {
              name = "prometheus"
              port {
                number = 9090
              }
            }
          }
        }
      }
    }

    # tls {
    #   hosts       = ["prometheus.local"]
    #   secret_name = "prometheus-tls"
    # }
  }
}