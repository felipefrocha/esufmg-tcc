variable "postgres_secret" {
  type = string
  sensitive = true
  description = "Pass database access"
}