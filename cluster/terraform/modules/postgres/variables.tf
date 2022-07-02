variable "storage_class_name" {
  type        = string
  description = "Storage Class Name to be used in statefulset volume claim"
}
variable "postgres_secret" {
  type = string
  sensitive = true
}