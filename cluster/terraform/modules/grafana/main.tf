resource "kubernetes_config_map_v1" "grafna" {
  metadata {
    name = "grafana-config"
  }

  data = {
    GF_DEFAULT_INSTANCE_NAME         = "grafana"
    GF_INSTALL_PLUGINS               = "grafana-clock-panel,grafana-simple-json-datasource,redis-datasource,grafana-newrelic-datasource"
    GF_INSTALL_IMAGE_RENDERER_PLUGIN = true
    # Config server
    GF_SERVER_ROOT_URL    = "https://grafana.local"
    GF_SERVER_DOMAIN      = "grafana.local"
    GF_SERVER_HTTP_PORT   = 3000
    GF_SERVER_ENABLE_GZIP = true
    # Config Github login
    # GF_AUTH_GITHUB_ENABLED=true
    # GF_AUTH_GITHUB_ALLOW_SIGN_UP=true
    # GF_AUTH_GITHUB_ALLOWED_ORGANIZATIONS=dccufmg
    # GF_AUTH_GITHUB_API_URL=
    # GF_AUTH_GITHUB_AUTH_URL=
    # GF_AUTH_GITHUB_TOKEN_URL=
    # GF_AUTH_GITHUB_CLIENT_ID=
    # GF_AUTH_GITHUB_CLIENT_SECRET=
    # GF_AUTH_GITHUB_SCOPES=user:email,read:org
    # GF_DEFAULT_HOME_DASHBOARD_PATH=
    # Data Base config
    GF_DATABASE_TYPE              = "postgres"
    GF_DATABASE_HOST              = "postgres:5432"
    GF_DATABASE_NAME              = "grafana"
    GF_DATABASE_USER              = "postgres"
    GF_DATABASE_PASSWORD          = "${var.postgres_secret}"
    GF_DATABASE_MAX_IDLE_CON      = 2
    GF_DATABASE_MAX_OPEN_CON      = 5
    GF_DATABASE_CONN_MAX_LIFETIME = 3600
    # GF_REMOTE_CACHE_TYPE=redis
    # GF_REMOTE_CACHE_CONNSTR="addr=redis:6379,pool_size=100,db=0,ssl=false"
  }
}

resource "kubernetes_deployment" "grafana" {
  metadata {
    name = "grafana"
    labels = {
      app = "grafana"
    }
  }
  spec {
    selector {
      match_labels = {
        app = "grafana"
      }
    }
    template {
      metadata {
        labels = {
          app = "grafana"
        }
      }
      spec {
        container {
          name            = "grafana"
          image           = "grafana/grafana:latest"
          image_pull_policy =  "IfNotPresent"
          port {
            container_port = 3000
            name           = "http-grafana"
            protocol       = "TCP"
          }
          readiness_probe {
            failure_threshold = 6
            http_get {
              path   = "/robots.txt"
              port   = 3000
              scheme = "HTTP"
            }
            initial_delay_seconds = 10
            period_seconds        = 30
            success_threshold     = 1
            timeout_seconds       = 2
          }
          liveness_probe {
            failure_threshold = 6
            tcp_socket {
              port = 3000
            }
            initial_delay_seconds = 10
            period_seconds        = 30
            success_threshold     = 1
            timeout_seconds       = 2
          }
          resources {
            limits = {
              cpu    = "300m"
              memory = "1000Mi"
            }

            requests = {
              cpu    = "200m"
              memory = "750Mi"
            }
          }
          env_from {
            config_map_ref {
              name = "grafana-config"
            }
          }
        }
      }
    }
  }
}

resource "kubernetes_service_v1" "grafana" {
  metadata {
    name = "grafana"
  }
  spec {
    selector = {
      app = kubernetes_deployment.grafana.metadata.0.labels.app
    }
    session_affinity = "ClientIP"
    port {
      port        = 3000
      target_port = 3000
      node_port = 31000
    }

    # type = "ClusterIP"
    type = "NodePort"
  }
}

resource "kubernetes_ingress_v1" "grafana" {
  metadata {
    name = "grafana-ingress"
  }

  spec {
    ingress_class_name = "nginx"

    default_backend {
      service {
        name = "grafana"
        port {
          number = 3000
        }
      }
    }

    rule {
      host = "grafana.local"
      http {
        path {
          backend {
            service {
              name = "grafana"
              port {
                number = 3000
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
          path      = "/grafana"
          backend {
            service {
              name = "grafana"
              port {
                number = 3000
              }
            }
          }
        }
      }
    }

    # tls {
    #   hosts       = ["grafana.local"]
    #   secret_name = "grafana-tls"
    # }
  }
}

