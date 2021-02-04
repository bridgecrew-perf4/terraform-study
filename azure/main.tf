############################
#    Terraform provider
############################
terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = ">= 2.26"
    }
  }
}

provider "azurerm" {
  features {}
}

############################
#    Azure Resource Group
############################
resource "azurerm_resource_group" "rg_kattest" {
  name     = "rg_kattest"
  location = "Japan East"
}

############################
#    Virtual NW
############################
resource "azurerm_virtual_network" "vnet_kattest" {
  name                = "vnet_kattest"
  address_space       = ["192.168.0.0/16"]
  location            = azurerm_resource_group.rg_kattest.location
  resource_group_name = azurerm_resource_group.rg_kattest.name
}

############################
#    Management Subnet
############################
# Subnet
resource "azurerm_subnet" "subnet_mgmt" {
  name                 = "subnet_mgmt"
  resource_group_name  = azurerm_resource_group.rg_kattest.name
  virtual_network_name = azurerm_virtual_network.vnet_kattest.name
  address_prefixes     = ["192.168.214.0/24"]
}

# Network SG
resource "azurerm_network_security_group" "nsg_mgmt" {
  name                = "nsg_mgmt"
  location            = azurerm_resource_group.rg_kattest.location
  resource_group_name = azurerm_resource_group.rg_kattest.name

  security_rule {
    name                       = "allow_ssh_any"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "192.168.214.0/24"
  }

}

# Network SG Association
resource "azurerm_subnet_network_security_group_association" "nsg1_mgmt_association" {
  subnet_id                 = azurerm_subnet.subnet_mgmt.id
  network_security_group_id = azurerm_network_security_group.nsg_mgmt.id
}

# NIC
resource "azurerm_network_interface" "nic_kattest" {
  name                = "nic_kattest"
  location            = azurerm_resource_group.rg_kattest.location
  resource_group_name = azurerm_resource_group.rg_kattest.name

  ip_configuration {
    name                          = "nic-kattest-ipaddr"
    subnet_id                     = azurerm_subnet.subnet_mgmt.id
    private_ip_address_allocation = "Static"
    private_ip_address            = "192.168.214.10"
  }
}

############################
#    App Subnet
############################
# Subnet
resource "azurerm_subnet" "subnet_app" {
  name                 = "subnet_app"
  resource_group_name  = azurerm_resource_group.rg_kattest.name
  virtual_network_name = azurerm_virtual_network.vnet_kattest.name
  address_prefixes     = ["192.168.215.0/24"]
}


##############
#    Virtual Machines
##############
# TBD
#resource "azurerm_virtual_machine" "vm_lin01" {
#}


#resource "azurerm_virtual_machine" "vm_win01" {
#}