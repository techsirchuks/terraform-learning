terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3.0"
    }
  }
}

provider "azurerm" {
  features {}
}

#Resource Group
resource "azurerm_resource_group" "terraform-learning-rg" {
  name     = "terraform-learning-rg"
  location = "South Africa North"
}

#Create Virtual Network
resource "azurerm_virtual_network" "g5-vnet" {
  name                = "g5-vnet"
  location            = azurerm_resource_group.terraform-learning-rg.location
  resource_group_name = azurerm_resource_group.terraform-learning-rg.name
  address_space       = ["10.0.0.0/16"]
}

# Subnet Creation
resource "azurerm_subnet" "g5-subnet" {
  name                 = "g5-subnet"
  resource_group_name  = azurerm_resource_group.terraform-learning-rg.name
  virtual_network_name = azurerm_virtual_network.g5-vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}