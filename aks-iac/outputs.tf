output "kubernetes_cluster_name" {
  description = "Nome do cluster Kubernetes (AKS)"
  value       = azurerm_kubernetes_cluster.encontros_devops_aks.name
}

output "resource_group_name" {
  description = "Nome do Resource Group"
  value       = azurerm_resource_group.encontros_devops_rg.name
}

output "postgres_host" {
  description = "Host do servidor PostgreSQL"
  value       = azurerm_postgresql_flexible_server.encontros_devops_db.fqdn
}

output "postgres_database_url" {
  description = "DATABASE_URL pronta para uso na aplicação"
  value       = "postgresql://psqladmin:${random_password.postgres_admin_password.result}@${azurerm_postgresql_flexible_server.encontros_devops_db.fqdn}:5432/encontros_devops?sslmode=require"
  sensitive   = true
}

