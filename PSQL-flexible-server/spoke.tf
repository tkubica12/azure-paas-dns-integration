# Spoke Resource Group
resource "azurerm_resource_group" "spoke" {
  name     = "spoke-rg"
  location = "West Europe"
}

# Spoke networking
resource "azurerm_virtual_network" "spoke" {
  name                = "spoke-net"
  location            = azurerm_resource_group.spoke.location
  resource_group_name = azurerm_resource_group.spoke.name
  address_space       = ["10.1.0.0/16"]
}

resource "azurerm_subnet" "spokepaas" {
  name                 = "paas-subnet"
  resource_group_name  = azurerm_resource_group.spoke.name
  virtual_network_name = azurerm_virtual_network.spoke.name
  address_prefixes     = ["10.1.0.0/24"]
  delegation {
    name = "fs"
    service_delegation {
      name = "Microsoft.DBforPostgreSQL/flexibleServers"
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/join/action",
      ]
    }
  }
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

# PSQL servers
resource "azurerm_postgresql_flexible_server" "psql1" {
  name                   = "psql1"
  resource_group_name    = azurerm_resource_group.spoke.name
  location               = azurerm_resource_group.spoke.location
  version                = "12"
  delegated_subnet_id    = azurerm_subnet.spokepaas.id
  private_dns_zone_id    = azurerm_private_dns_zone.dns.id
  administrator_login    = "tomas"
  administrator_password = "Azure12345678"

  storage_mb = 32768

  sku_name   = "B_Standard_B1ms"
  depends_on = [azurerm_private_dns_zone_virtual_network_link.dnsspoke]

}

resource "azurerm_postgresql_flexible_server" "psql2" {
  name                   = "psql2"
  resource_group_name    = azurerm_resource_group.spoke.name
  location               = azurerm_resource_group.spoke.location
  version                = "12"
  delegated_subnet_id    = azurerm_subnet.spokepaas.id
  private_dns_zone_id    = azurerm_private_dns_zone.dns.id
  administrator_login    = "tomas"
  administrator_password = "Azure12345678"

  storage_mb = 32768

  sku_name   = "B_Standard_B1ms"
  depends_on = [azurerm_private_dns_zone_virtual_network_link.dnsspoke]

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