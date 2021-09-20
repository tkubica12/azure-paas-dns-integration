variable "name" {
  description = "ccloud FQDN"
}

variable "description" {
  description = "Description to be added to description tag of each record"
}

variable "az1-ip" {
  description = "IP address of az1"
}

variable "az2-ip" {
  description = "IP address of az2"
}

variable "az3-ip" {
  description = "IP address of az3"
}

variable "parent-zone" {
  description = "Name of Azure DNS zone"
}

variable "parent-zone-resource-group" {
  description = "RG of Azure DNS zone"
}

resource "azurerm_private_dns_a_record" "ccloud-az1" {
  name                = "*.az1.${var.name}"
  zone_name           = var.parent-zone
  resource_group_name = var.parent-zone-resource-group
  ttl                 = 60
  records             = [var.az1-ip]
  tags = {
    description = var.description
  }
}

resource "azurerm_private_dns_a_record" "ccloud-az2" {
  name                = "*.az2.${var.name}"
  zone_name           = var.parent-zone
  resource_group_name = var.parent-zone-resource-group
  ttl                 = 60
  records             = [var.az2-ip]
  tags = {
    description = var.description
  }
}

resource "azurerm_private_dns_a_record" "ccloud-az3" {
  name                = "*.az3.${var.name}"
  zone_name           = var.parent-zone
  resource_group_name = var.parent-zone-resource-group
  ttl                 = 60
  records             = [var.az3-ip]
  tags = {
    description = var.description
  }
}

resource "azurerm_private_dns_a_record" "ccloud-main" {
  name                = "*.${var.name}"
  zone_name           = var.parent-zone
  resource_group_name = var.parent-zone-resource-group
  ttl                 = 60
  records = [
    var.az1-ip,
    var.az2-ip,
    var.az3-ip,
  ]
  tags = {
    description = var.description
  }
}
