# DNS resource group
resource "azurerm_resource_group" "dns" {
  name     = "psql-dns-rg"
  location = "West Europe"
}


# Private zone
resource "azurerm_private_dns_zone" "dns" {
  name                = "mycustomname.postgres.database.azure.com"
  resource_group_name = azurerm_resource_group.dns.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "dnsspoke" {
  name                  = "netlinkspoke"
  private_dns_zone_name = azurerm_private_dns_zone.dns.name
  virtual_network_id    = azurerm_virtual_network.spoke.id
  resource_group_name   = azurerm_resource_group.dns.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "dnshub" {
  name                  = "netlinkhub"
  private_dns_zone_name = azurerm_private_dns_zone.dns.name
  virtual_network_id    = azurerm_virtual_network.hub.id
  resource_group_name   = azurerm_resource_group.dns.name
}