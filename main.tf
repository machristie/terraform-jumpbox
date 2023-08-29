# Configure the Azure provider
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0.2"
    }
  }

  required_version = ">= 1.1.0"
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
}

resource "azurerm_virtual_network" "vnet" {
  name                = var.vnet_name
  address_space       = var.vnet_address_space
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_subnet" "jumpbox_subnet" {
  name                 = var.jumpbox_subnet_name
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = var.jumpbox_subnet_address_prefixes
}

resource "azurerm_subnet" "vm_subnet" {
  name                 = var.vm_subnet_name
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = var.vm_subnet_address_prefixes
}

# jumpbox's public ip
resource "azurerm_public_ip" "jumpbox_public_ip" {
  name                = "jumpbox-public-ip"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Dynamic"
}

# jumpbox's nic to jumpbox-subnet
resource "azurerm_network_interface" "jumpbox_nic" {
  name                = "jumpbox_nic"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "jumpbox_nic_configuration"
    subnet_id                     = azurerm_subnet.jumpbox_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.jumpbox_public_ip.id
  }
}


# allow SSH on jumpbox's nic
resource "azurerm_network_interface_security_group_association" "jumpbox_nic_nsg_association" {
  network_interface_id      = azurerm_network_interface.jumpbox_nic.id
  network_security_group_id = azurerm_network_security_group.jumpbox_nic_nsg.id
}

# VM's nic to vm_subnet
resource "azurerm_network_interface" "vm_nic" {
  name                = "vm_nic"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "vm_nic_configuration"
    subnet_id                     = azurerm_subnet.vm_subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

# azurerm_network_security_group to allow SSH (port 22)
resource "azurerm_network_security_group" "jumpbox_nic_nsg" {
  name                = "jumpbox_nic_nsg"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_network_security_rule" "allow_ssh" {
  network_security_group_name = azurerm_network_security_group.jumpbox_nic_nsg.name
  resource_group_name         = azurerm_resource_group.rg.name
  name                        = "SSH"
  priority                    = 1001
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "22"
  source_address_prefixes     = var.jumpbox_nsg_allow_ssh_address_prefixes
  destination_address_prefix  = "*"
}

resource "azurerm_network_security_group" "vm_subnet_nsg" {
  name                = "nsg-vm-subnet"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_network_security_rule" "from_jumpbox_allow_ssh" {
  network_security_group_name = azurerm_network_security_group.vm_subnet_nsg.name
  resource_group_name         = azurerm_resource_group.rg.name

  name                       = "SSH"
  priority                   = 500
  direction                  = "Inbound"
  access                     = "Allow"
  protocol                   = "Tcp"
  source_port_range          = "*"
  destination_port_range     = "22"
  source_address_prefix      = azurerm_subnet.jumpbox_subnet.address_prefixes[0]
  destination_address_prefix = azurerm_subnet.vm_subnet.address_prefixes[0]
}

resource "azurerm_network_security_rule" "from_jumpbox_disallow_all" {
  network_security_group_name = azurerm_network_security_group.vm_subnet_nsg.name
  resource_group_name         = azurerm_resource_group.rg.name

  name                       = "Inbound_Deny_from_jumpbox"
  priority                   = 1000
  direction                  = "Inbound"
  access                     = "Deny"
  protocol                   = "Tcp"
  source_port_range          = "*"
  destination_port_range     = "*"
  source_address_prefix      = azurerm_subnet.jumpbox_subnet.address_prefixes[0]
  destination_address_prefix = azurerm_subnet.vm_subnet.address_prefixes[0]
}

resource "azurerm_subnet_network_security_group_association" "nsg_vm_subnet_association" {
  network_security_group_id = azurerm_network_security_group.vm_subnet_nsg.id
  subnet_id                 = azurerm_subnet.vm_subnet.id
}

# azurerm_linux_virtual_machine, create the application VM
resource "azurerm_linux_virtual_machine" "vm" {
  name                  = "app-vm"
  location              = azurerm_resource_group.rg.location
  resource_group_name   = azurerm_resource_group.rg.name
  network_interface_ids = [azurerm_network_interface.vm_nic.id]
  size                  = "Standard_B1s"

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "erockyenterprisesoftwarefoundationinc1653071250513"
    offer     = "rockylinux"
    sku       = "free"
    version   = "8.7.20230215"
  }

  # Got the plan information from output of running:
  #   az vm image show --location eastus --urn erockyenterprisesoftwarefoundationinc1653071250513:rockylinux:free:8.7.20230215
  plan {
    name      = "free"
    product   = "rockylinux"
    publisher = "erockyenterprisesoftwarefoundationinc1653071250513"
  }

  admin_username = var.username

  admin_ssh_key {
    username   = var.username
    public_key = file("~/.ssh/gt.pub")
  }
}

# jumpbox VM, a minimal Ubuntu LTS VM
resource "azurerm_linux_virtual_machine" "jumpbox" {
  name                  = "jumpbox-vm"
  location              = azurerm_resource_group.rg.location
  resource_group_name   = azurerm_resource_group.rg.name
  network_interface_ids = [azurerm_network_interface.jumpbox_nic.id]
  size                  = "Standard_B1ls"

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-minimal-jammy"
    sku       = "minimal-22_04-lts"
    version   = "latest"
  }

  admin_username = var.jumpbox_username

  admin_ssh_key {
    username   = var.jumpbox_username
    public_key = file("~/.ssh/gt.pub")
  }
}
