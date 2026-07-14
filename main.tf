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
resource "azurerm_resource_group" "g5-rg" {
  name     = "g5-rg"
  location = "South Africa North"
}

#Create Virtual Network
resource "azurerm_virtual_network" "g5-vnet" {
  name                = "g5-vnet"
  location            = azurerm_resource_group.g5-rg.location
  resource_group_name = azurerm_resource_group.g5-rg.name
  address_space       = ["10.0.0.0/16"]
}

# Subnet Creation
resource "azurerm_subnet" "frontend-subnet" {
  name                 = "frontend-subnet"
  resource_group_name  = azurerm_resource_group.g5-rg.name
  virtual_network_name = azurerm_virtual_network.g5-vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_subnet" "backend-subnet" {
  name                 = "backend-subnet"
  resource_group_name  = azurerm_resource_group.g5-rg.name
  virtual_network_name = azurerm_virtual_network.g5-vnet.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_subnet" "database-subnet" {
  name                 = "database-subnet"
  resource_group_name  = azurerm_resource_group.g5-rg.name
  virtual_network_name = azurerm_virtual_network.g5-vnet.name
  address_prefixes     = ["10.0.3.0/24"]
}

# Create Public IP
resource "azurerm_public_ip" "g5-ip" {
  name                = "g5-ip"
  resource_group_name = azurerm_resource_group.g5-rg.name
  location            = azurerm_resource_group.g5-rg.location
  allocation_method   = "Static"
  sku                 = "Standard"
}  

# Create NSG
resource "azurerm_network_security_group" "frontend-nsg"{
  name                = "frontend-nsg"
  location            = azurerm_resource_group.g5-rg.location
  resource_group_name = azurerm_resource_group.g5-rg.name

  # NSG rule forallowing port 22

  security_rule {
    name                       = "Allow-SSH"
    priority                   = "100"
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}