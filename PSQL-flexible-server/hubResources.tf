# Hub Resource Group
resource "azurerm_resource_group" "hub" {
  name     = "psql-hub-rg"
  location = "West Europe"
}

# Hub networking
resource "azurerm_virtual_network" "hub" {
  name                = "hub-net"
  location            = azurerm_resource_group.hub.location
  resource_group_name = azurerm_resource_group.hub.name
  address_space       = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "hubvm" {
  name                 = "vm-subnet"
  resource_group_name  = azurerm_resource_group.hub.name
  virtual_network_name = azurerm_virtual_network.hub.name
  address_prefixes     = ["10.0.0.0/24"]
}

resource "azurerm_subnet" "hubdns" {
  name                 = "dns-subnet"
  resource_group_name  = azurerm_resource_group.hub.name
  virtual_network_name = azurerm_virtual_network.hub.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_virtual_network_peering" "hub-2-spoke" {
  name                      = "hub-2-spoke"
  resource_group_name       = azurerm_resource_group.hub.name
  virtual_network_name      = azurerm_virtual_network.hub.name
  remote_virtual_network_id = azurerm_virtual_network.spoke.id
}

# Hub VM
resource "azurerm_storage_account" "hubstorage" {
    name                        = "diaghub${random_id.randomId.hex}"
    resource_group_name         = azurerm_resource_group.hub.name
    location                    = azurerm_resource_group.hub.location
    account_tier                = "Standard"
    account_replication_type    = "LRS"
}

resource "azurerm_network_interface" "hubvmnic" {
    name                      = "hubvmnic"
    location                  = azurerm_resource_group.hub.location
    resource_group_name       = azurerm_resource_group.hub.name

    ip_configuration {
        name                          = "myNicConfiguration"
        subnet_id                     = azurerm_subnet.hubvm.id
        private_ip_address_allocation = "Dynamic"
    }
}

resource "azurerm_linux_virtual_machine" "hubvm" {
    name                  = "hubvm"
    location              = azurerm_resource_group.hub.location
    resource_group_name   = azurerm_resource_group.hub.name
    network_interface_ids = [azurerm_network_interface.hubvmnic.id]
    size                  = "Standard_B1ms"

    os_disk {
        name              = "hubvm"
        caching           = "ReadWrite"
        storage_account_type = "Standard_LRS"
    }

    source_image_reference {
        publisher = "Canonical"
        offer     = "UbuntuServer"
        sku       = "18.04-LTS"
        version   = "latest"
    }

    computer_name  = "hubvm"
    admin_username = "tomas"
    admin_password = "Azure12345678"
    disable_password_authentication = false

    boot_diagnostics {
        storage_account_uri = azurerm_storage_account.hubstorage.primary_blob_endpoint
    }
}

# Hub DNS server VM
resource "azurerm_network_interface" "hubvmdns" {
    name                      = "hubvmdns"
    location                  = azurerm_resource_group.hub.location
    resource_group_name       = azurerm_resource_group.hub.name

    ip_configuration {
        name                          = "myNicConfiguration"
        subnet_id                     = azurerm_subnet.hubdns.id
        private_ip_address_allocation = "Static"
        private_ip_address            = "10.0.1.4"
    }
}

resource "azurerm_linux_virtual_machine" "hubvmdns" {
    name                  = "hubvmdns"
    location              = azurerm_resource_group.hub.location
    resource_group_name   = azurerm_resource_group.hub.name
    network_interface_ids = [azurerm_network_interface.hubvmdns.id]
    size                  = "Standard_B1ms"

    os_disk {
        name              = "hubvmdns"
        caching           = "ReadWrite"
        storage_account_type = "Standard_LRS"
    }

    source_image_reference {
        publisher = "Canonical"
        offer     = "UbuntuServer"
        sku       = "18.04-LTS"
        version   = "latest"
    }

    computer_name  = "hubvm"
    admin_username = "tomas"
    admin_password = "Azure12345678"
    disable_password_authentication = false

    boot_diagnostics {
        storage_account_uri = azurerm_storage_account.hubstorage.primary_blob_endpoint
    }
}

resource "azurerm_virtual_machine_extension" "hubvmdns" {
  name                 = "hubvmdns"
  virtual_machine_id   = azurerm_linux_virtual_machine.hubvmdns.id
  publisher            = "Microsoft.Azure.Extensions"
  type                 = "CustomScript"
  type_handler_version = "2.1"

  settings = <<SETTINGS
    {
        "commandToExecute": "./installBind.sh",
        "fileUris": ["https://github.com/tkubica12/azure-paas-dns-integration/raw/master/scripts/installBind.sh"]
    }
SETTINGS
}