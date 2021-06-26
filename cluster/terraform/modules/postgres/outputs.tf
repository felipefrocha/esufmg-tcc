output "service_comm" {
  value = element(kubernetes_service.postgres.metadata.*.name, 0)
}