resource "azurerm_kubernetes_cluster" "encontros_devops_aks" {
  name                = "aks-encontros-devops"
  location            = azurerm_resource_group.encontros_devops_rg.location
  resource_group_name = azurerm_resource_group.encontros_devops_rg.name
  dns_prefix          = "aks-encontros-devops"

  default_node_pool {
    name       = "default"
    node_count = 1
    vm_size    = "Standard_B2s_v2"
  }

  identity {
    type = "SystemAssigned"
  }

  oidc_issuer_enabled = true
}

resource "local_sensitive_file" "kubeconfig" {
  content         = azurerm_kubernetes_cluster.encontros_devops_aks.kube_config_raw
  filename        = "${path.module}/kubeconfig"
  file_permission = "0600"
}