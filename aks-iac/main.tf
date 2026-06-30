terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=4.1.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  subscription_id = var.subscription_id
  features {}
}

provider "kubernetes" {
  host                   = azurerm_kubernetes_cluster.encontros_devops_aks.kube_config[0].host
  client_certificate     = base64decode(azurerm_kubernetes_cluster.encontros_devops_aks.kube_config[0].client_certificate)
  client_key             = base64decode(azurerm_kubernetes_cluster.encontros_devops_aks.kube_config[0].client_key)
  cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.encontros_devops_aks.kube_config[0].cluster_ca_certificate)
}

resource "azurerm_resource_group" "encontros_devops_rg" {
  name     = "rg-encontros-devops"
  location = "East US"
}

module "vnet" {
  source = "./modules/vnet"

  vnet_name             = "vnet-encontro-devops"
  location              = azurerm_resource_group.encontros_devops_rg.location
  resource_group_name   = azurerm_resource_group.encontros_devops_rg.name
  vnet_address_space    = "10.0.0.0/16"
  subnet_name           = "snet-encontro-001"
  subnet_address_prefix = "10.0.1.0/24"
}