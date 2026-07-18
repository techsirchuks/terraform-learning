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
resource "azurerm_public_ip" "frontend-ip" {
  name                = "frontend-ip"
  resource_group_name = azurerm_resource_group.g5-rg.name
  location            = azurerm_resource_group.g5-rg.location
  allocation_method   = "Static"
  sku                 = "Standard"
}

# Create NSG
resource "azurerm_network_security_group" "frontend-nsg" {
  name                = "frontend-nsg"
  location            = azurerm_resource_group.g5-rg.location
  resource_group_name = azurerm_resource_group.g5-rg.name
}

#NSG rule for allowing port 80
resource "azurerm_network_security_rule" "allow-http" {
  name                        = "allow-http"
  priority                    = "100"
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "80"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.g5-rg.name
  network_security_group_name = azurerm_network_security_group.frontend-nsg.name
}


#NSG rule for allowing port 443
resource "azurerm_network_security_rule" "allow-https" {
  name                        = "allow-https"
  priority                    = "120"
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "443"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.g5-rg.name
  network_security_group_name = azurerm_network_security_group.frontend-nsg.name
}


#NSG rule for denying all other traffic
resource "azurerm_network_security_rule" "deny-all" {
  name                        = "deny-all"
  priority                    = "4096"
  direction                   = "Inbound"
  access                      = "Deny"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.g5-rg.name
  network_security_group_name = azurerm_network_security_group.frontend-nsg.name
}


#NSG Rule to open port 22
resource "azurerm_network_security_rule" "allow-SSH" {
  name                        = "allow-SSH"
  priority                    = "300"
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "22"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.g5-rg.name
  network_security_group_name = azurerm_network_security_group.frontend-nsg.name
}


#NIC for the VM
resource "azurerm_network_interface" "g5-nic" {
  name                = "g5-nic"
  location            = azurerm_resource_group.g5-rg.location
  resource_group_name = azurerm_resource_group.g5-rg.name

  ip_configuration {
    name                          = "front-ip"
    subnet_id                     = azurerm_subnet.frontend-subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.frontend-ip.id
  }
}

#NIC Association
resource "azurerm_network_interface_security_group_association" "g5-nic-asso" {
  network_interface_id      = azurerm_network_interface.g5-nic.id
  network_security_group_id = azurerm_network_security_group.frontend-nsg.id
}

#LInux VM Creation
resource "azurerm_linux_virtual_machine" "g5-vm" {
  name                = "g5-vm"
  resource_group_name = azurerm_resource_group.g5-rg.name
  location            = azurerm_resource_group.g5-rg.location
  size                = "Standard_B2ts_v2"
  admin_username      = "azureuser"
  network_interface_ids = [
    azurerm_network_interface.g5-nic.id
  ]

  admin_ssh_key {
    username   = "azureuser"
    public_key = file("~/.ssh/id_rsa.pub")
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "Ubuntu-24_04-lts"
    sku       = "server"
    version   = "latest"
  }
}
output "vm_public_ip" {
  value = "azurerm_public_ip.g5-vm.address"
}