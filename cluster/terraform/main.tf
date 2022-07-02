

# resource "helm_release" "nfs_subdir_provisioner" {
#   name       = "grafana-ufmg"
#   repository = "https://kubernetes-sigs.github.io/nfs-subdir-external-provisioner/"
#   chart      = "nfs-subdir-external-provisioner"
#   namespace  = "nfs-provisioner"

#   values = [
#     "nfs.server = k8s-haproxy",
#     "nfs.path = /export/volumes"
#   ]
# }
# resource "kubernetes_persistent_volume" "postgres" {
#   metadata {
#     name = "pv-postgres"
#   }
#   spec {
#     capacity = {
#       storage = "10Gi"
#     }
#     access_modes = ["ReadWriteOnce"]
#     persistent_volume_reclaim_policy = "Delete"
#     mount_options = [ "nfsvers=4.1" ]
#     persistent_volume_source {
#       csi  {
#         driver = "nfs.csi.k8s"
#         read_only = false
#         volume_handle = "unique-volumeid"
#         volume_attributes = {
#           server = "k8s-haproxy"
#           share ="/export/volumes/pv-postgres"
#         }
#       }
#     }
#   }
# }

module "shared_postgres" {
  source             = "./modules/postgres"
  storage_class_name = element(kubernetes_storage_class.nfs.metadata.*.name, 0)
  postgres_secret    = "N3w4dm1nS"
}

# module "monitoring_grafana" {
#   source          = "./modules/grafana"
#   postgres_secret = "N3w4dm1nS"
# }


# module "monitoring_prometheus" {
#   source          = "./modules/prometheus"
# }