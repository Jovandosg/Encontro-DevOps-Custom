variable "subscription_id" {
  type = string
}

variable "postgres_location" {
  type        = string
  description = "Região para o PostgreSQL Flexible Server (pode ser diferente do AKS)"
  default     = "eastus2"
}
