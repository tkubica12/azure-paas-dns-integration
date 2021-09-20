# Spoke Resource Group
resource "azurerm_resource_group" "spoke" {
  name     = "ccloud-spoke-rg"
  location = "West Europe"
}

# Spoke networking
resource "azurerm_virtual_network" "spoke" {
  name                = "spoke-net"
  location            = azurerm_resource_group.spoke.location
  resource_group_name = azurerm_resource_group.spoke.name
  address_space       = ["10.1.0.0/16"]
  dns_servers         = ["10.0.0.4"]
  depends_on          = [azurerm_virtual_machine_extension.hubvmdns]
}

resource "azurerm_subnet" "spokepaas" {
  name                 = "paas-subnet"
  resource_group_name  = azurerm_resource_group.spoke.name
  virtual_network_name = azurerm_virtual_network.spoke.name
  address_prefixes     = ["10.1.0.0/24"]
}

resource "azurerm_subnet" "spokevm" {
  name                 = "vm-subnet"
  resource_group_name  = azurerm_resource_group.spoke.name
  virtual_network_name = azurerm_virtual_network.spoke.name
  address_prefixes     = ["10.1.1.0/24"]
}

resource "azurerm_virtual_network_peering" "spoke-2-hub" {
  name                      = "spoke-2-hub"
  resource_group_name       = azurerm_resource_group.spoke.name
  virtual_network_name      = azurerm_virtual_network.spoke.name
  remote_virtual_network_id = azurerm_virtual_network.hub.id
}

# App VM
resource "azurerm_storage_account" "spokestorage" {
    name                        = "diags${random_id.randomId.hex}"
    resource_group_name         = azurerm_resource_group.spoke.name
    location                    = azurerm_resource_group.spoke.location
    account_tier                = "Standard"
    account_replication_type    = "LRS"
}

resource "azurerm_network_interface" "appvmnic" {
    name                      = "appvmnic"
    location                  = azurerm_resource_group.spoke.location
    resource_group_name       = azurerm_resource_group.spoke.name

    ip_configuration {
        name                          = "myNicConfiguration"
        subnet_id                     = azurerm_subnet.spokevm.id
        private_ip_address_allocation = "Dynamic"
    }
}

resource "azurerm_linux_virtual_machine" "appvm" {
    name                  = "appvm"
    location              = azurerm_resource_group.spoke.location
    resource_group_name   = azurerm_resource_group.spoke.name
    network_interface_ids = [azurerm_network_interface.appvmnic.id]
    size                  = "Standard_B1ms"

    os_disk {
        name              = "appvm"
        caching           = "ReadWrite"
        storage_account_type = "Standard_LRS"
    }

    source_image_reference {
        publisher = "Canonical"
        offer     = "UbuntuServer"
        sku       = "18.04-LTS"
        version   = "latest"
    }

    computer_name  = "appvm"
    admin_username = "tomas"
    admin_password = "Azure12345678"
    disable_password_authentication = false

    boot_diagnostics {
        storage_account_uri = azurerm_storage_account.spokestorage.primary_blob_endpoint
    }
}