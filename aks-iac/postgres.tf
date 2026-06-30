resource "random_password" "postgres_admin_password" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "azurerm_postgresql_flexible_server" "encontros_devops_db" {
  name                   = "psql-encontros-devops"
  resource_group_name    = azurerm_resource_group.encontros_devops_rg.name
  location               = var.postgres_location
  version                = "16"
  administrator_login    = "psqladmin"
  administrator_password = random_password.postgres_admin_password.result

  # SKU mais barato: Burstable B1ms (~$12/mês)
  sku_name   = "B_Standard_B1ms"
  storage_mb = 32768 # 32 GB (mínimo)

  backup_retention_days        = 7
  geo_redundant_backup_enabled = false
}

resource "azurerm_postgresql_flexible_server_database" "encontros_devops" {
  name      = "encontros_devops"
  server_id = azurerm_postgresql_flexible_server.encontros_devops_db.id
  collation = "en_US.utf8"
  charset   = "utf8"
}

# Permite acesso de todos os serviços Azure (incluindo AKS)
resource "azurerm_postgresql_flexible_server_firewall_rule" "allow_azure_services" {
  name             = "allow-azure-services"
  server_id        = azurerm_postgresql_flexible_server.encontros_devops_db.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
}
