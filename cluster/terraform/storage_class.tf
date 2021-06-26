resource "kubernetes_storage_class" "nfs" {
  metadata {
    name = "nfs-csi"
  }

  storage_provisioner = "nfs.csi.k8s.io"

  reclaim_policy      = "Delete"
  volume_binding_mode = "Immediate"

  parameters = {
    server = "k8s-haproxy"
    share  = "/export/volumes/"
  }

  mount_options = ["nfsvers=4.1", "hard"]
}
