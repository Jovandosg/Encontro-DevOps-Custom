variable "vnet_name" {
  type        = string
  description = "Nome da Virtual Network"
}

variable "location" {
  type        = string
  description = "Região Azure onde a VNet será criada"
}

variable "resource_group_name" {
  type        = string
  description = "Nome do Resource Group"
}

variable "vnet_address_space" {
  type        = string
  description = "Bloco CIDR da Virtual Network"
  default     = "10.0.0.0/16"
}

variable "subnet_name" {
  type        = string
  description = "Nome da subnet"
}

variable "subnet_address_prefix" {
  type        = string
  description = "Bloco CIDR da subnet (/24 = 251 hosts disponíveis)"
  default     = "10.0.1.0/24"
}
