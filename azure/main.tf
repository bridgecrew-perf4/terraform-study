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
#    Global IP addrs
############################
resource "azurerm_public_ip" "gip1" {
  name                = "gip1"
  resource_group_name = azurerm_resource_group.rg_kattest.name
  location            = azurerm_resource_group.rg_kattest.location
  allocation_method   = "Static"
}

resource "azurerm_public_ip" "gip2" {
  name                = "gip2"
  resource_group_name = azurerm_resource_group.rg_kattest.name
  location            = azurerm_resource_group.rg_kattest.location
  allocation_method   = "Static"
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
resource "azurerm_network_interface" "nic1_lin01" {
  name                = "nic1_lin01"
  location            = azurerm_resource_group.rg_kattest.location
  resource_group_name = azurerm_resource_group.rg_kattest.name

  ip_configuration {
    name                          = "nic1_lin01_ipaddr"
    subnet_id                     = azurerm_subnet.subnet_mgmt.id
    private_ip_address_allocation = "Static"
    private_ip_address            = "192.168.214.10"
    public_ip_address_id          = azurerm_public_ip.gip1.id
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


############################
#    Virtual Machines
############################

# Linux VM
resource "azurerm_virtual_machine" "vm_lin01" {
  name                  = "vm_lin01"
  location              = azurerm_resource_group.rg_kattest.location
  resource_group_name   = azurerm_resource_group.rg_kattest.name
  network_interface_ids = [azurerm_network_interface.nic1_lin01.id]
  vm_size               = "Standard_DS2_v2"

  delete_os_disk_on_termination = true
  delete_data_disks_on_termination = true

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  storage_os_disk {
    name              = "os_disk_lin01"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name  = "lin01"
    admin_username = "kattest"
  }

  os_profile_linux_config {
    disable_password_authentication = true
    ssh_keys {
      path     = "/home/kattest/.ssh/authorized_keys"
      key_data = file("/Users/kenichi/.ssh/id_rsa.pub")
    }
  }
}

# Win VM
#resource "azurerm_virtual_machine" "vm_win01" {
#}