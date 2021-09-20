# DNS resource group
resource "azurerm_resource_group" "dns" {
  name     = "ccloud-dns-rg"
  location = "West Europe"
}


# Private zone
resource "azurerm_private_dns_zone" "dns" {
  name                = "westeurope.azure.confluent.cloud"
  resource_group_name = azurerm_resource_group.dns.name
}

# Loop to maintain all ccloud entries
module "records" {
  for_each                   = yamldecode(file("./ccloudInstances.yaml"))
  source                     = "./modules/ccloudRecord"
  parent-zone                = azurerm_private_dns_zone.dns.name
  parent-zone-resource-group = azurerm_resource_group.dns.name
  name                       = each.key
  az1-ip                     = each.value.az1
  az2-ip                     = each.value.az2
  az3-ip                     = each.value.az3
  description                = each.value.description
}



# output "log" {
#   value = yamldecode(file("./ccloudInstances.yaml"))
# }
