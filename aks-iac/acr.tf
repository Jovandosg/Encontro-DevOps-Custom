resource "azurerm_container_registry" "encontros_devops_acr" {
  name                = "acrencontrosdevops" # nome único global
  resource_group_name = azurerm_resource_group.encontros_devops_rg.name
  location            = azurerm_resource_group.encontros_devops_rg.location
  sku                 = "Premium"
  admin_enabled       = false
}