output "vnet_id" {
  description = "ID da Virtual Network criada"
  value       = azurerm_virtual_network.vnet.id
}

output "vnet_name" {
  description = "Nome da Virtual Network criada"
  value       = azurerm_virtual_network.vnet.name
}

output "subnet_id" {
  description = "ID da subnet criada"
  value       = azurerm_subnet.snet_001.id
}

output "subnet_name" {
  description = "Nome da subnet criada"
  value       = azurerm_subnet.snet_001.name
}
