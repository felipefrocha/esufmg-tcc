resource "helm_release" "csi_nfs" {
  name       = "csi-nfs"
  repository = "csi-driver-nfs"
  chart      = "csi-driver-nfs"
  namespace  = "kube-system"
}

# resource "helm_release" "nfs_subdir" {
#   name       = "csi-nfs"
#   repository = "csi-driver-nfs"
#   chart      = "csi-driver-nfs"
#   namespace  = "kube-system"

#     values = [
#        "${file("./data/helm/nfs-subdir-values.yaml")}"
#     ]
#   depends_on = [
#     helm_release.csi_nfs
#   ]
# }

# resource "helm_release" "ingress" {
#   name       = "ingress-nginx"
#   repository = "https://kubernetes.github.io/ingress-nginx"
#   chart      = "ingress-nginx"
#   namespace  = "ingress-nginx"

#     values = [
#       "${file("./data/helm/ingress-values.yaml")}"
#     ]
# }

# ## monitor
resource "kubernetes_namespace_v1" "monitoring" {
  metadata {
    name = "monitoring"
  }
}

resource "helm_release" "prometheus" {
  name       = "prometheus"
  repository = "prometheus-community"
  chart      =  "kube-prometheus-stack"
  namespace = kubernetes_namespace_v1.monitoring.metadata.0.name
  values = [
    "${file("./data/helm/prom-values.yaml")}"
  ]
}

resource "helm_release" "spark_operator" {
  name       = "spark-operator"
  repository = "spark-operator"
  chart      = "spark-operator "
  # namespace = "default"
  values = [
    "${file("./data/helm/sparkop-values.yaml")}"
  ]
}

resource "helm_release" "jupyterhub" {
  name       = "jupyterhub"
  repository = "jupyterhub"
  chart      = "jupyterhub"
  # namespace = "default"
  values = [
    "${file("./data/helm/jupyterhub-values.yaml")}"
  ]
}

resource "kubernetes_namespace_v1" "airflow" {
  metadata {
    name = "airflow"
  }
}

resource "helm_release" "airflow" {
  name       ="airflow"
  repository ="apache-airflow"
  chart      ="airflow"

  namespace ="airflow"
  
  wait_for_jobs = false
  wait = false
  
  atomic = false
  
  set {
    name  = "airflow.dbMigrations.runAsJob"
    value = "true"
  }
  
  values = [
    "${file("./data/helm/airflow-values.yaml")}"
  ]
}