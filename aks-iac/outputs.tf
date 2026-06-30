output "kubernetes_cluster_name" {
  description = "Nome do cluster Kubernetes (AKS)"
  value       = azurerm_kubernetes_cluster.encontros_devops_aks.name
}

output "resource_group_name" {
  description = "Nome do Resource Group"
  value       = azurerm_resource_group.encontros_devops_rg.name
}

output "postgres_host" {
  description = "Host do servidor PostgreSQL (DNS interno do AKS)"
  value       = "postgres.postgres.svc.cluster.local"
}

output "postgres_database_url" {
  description = "DATABASE_URL pronta para uso na aplicação"
  value       = "postgresql://psqladmin:${random_password.postgres_admin_password.result}@postgres.postgres.svc.cluster.local:5432/encontros_devops"
  sensitive   = true
}

