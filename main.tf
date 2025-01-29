provider "azurerm" {
  features {}
}

variable "vm_name" {
  description = "Name of the Virtual Machine"
  default     = "test-vm"
}

variable "resource_group_name" {
  description = "Resource Group Name"
  default     = "terraform-rg"
}

variable "location" {
  description = "Azure Region"
  default     = "East US"
}

resource "azurerm_resource_group" "vm_rg" {
  name     = var.resource_group_name
  location = var.location
}

resource "azurerm_virtual_network" "vm_vnet" {
  name                = "MyVNet"
  address_space       = ["10.0.0.0/16"]
  location            = var.location
  resource_group_name = azurerm_resource_group.vm_rg.name
}

resource "azurerm_subnet" "vm_subnet" {
  name                 = "MySubnet"
  resource_group_name  = azurerm_resource_group.vm_rg.name
  virtual_network_name = azurerm_virtual_network.vm_vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_public_ip" "vm_public_ip" {
  name                = "${var.vm_name}-public-ip"
  location            = var.location
  resource_group_name = azurerm_resource_group.vm_rg.name
  allocation_method   = "Dynamic"
}

resource "azurerm_network_interface" "vm_nic" {
  name                = "${var.vm_name}-nic"
  location            = var.location
  resource_group_name = azurerm_resource_group.vm_rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.vm_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.vm_public_ip.id
  }
}

resource "azurerm_storage_account" "vm_storage" {
  name                     = "vmstorageacct123"
  resource_group_name      = azurerm_resource_group.vm_rg.name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_linux_virtual_machine" "vm" {
  name                  = var.vm_name
  location              = var.location
  resource_group_name   = azurerm_resource_group.vm_rg.name
  network_interface_ids = [azurerm_network_interface.vm_nic.id]
  size                  = "Standard_B1s"
  admin_username        = "bodiua"
  admin_password        = "P@ssw0rd1234!" # For demo purposes; consider using SSH keys.

  disable_password_authentication = false

  os_disk {
    name                 = "${var.vm_name}_disk1"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    disk_size_gb         = 30
  }

  source_image_reference {
    publisher = "canonical"
    offer     = "0001-com-ubuntu-server-focal"
    sku       = "20_04-lts"
    version   = "latest"
  }

  boot_diagnostics {
    storage_account_uri = azurerm_storage_account.vm_storage.primary_blob_endpoint
  }
}