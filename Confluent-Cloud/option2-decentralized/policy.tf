resource "azurerm_policy_definition" "policy" {
  name         = "linkDnsZoneToHub"
  policy_type  = "Custom"
  mode         = "Indexed"
  display_name = "Link DNS zone to hub VNET"

  metadata = <<METADATA
    {
    "category": "General"
    }

METADATA


  policy_rule = <<POLICY_RULE
    {
    "if": {
        "field": "type",
        "equals": "Microsoft.Network/privateDnsZones"
    },
    "then": {
      "effect": "DeployIfNotExists",
      "details": {
        "type": "Microsoft.Network/privateDnsZones/virtualNetworkLinks",
        "name": "linkToHub",
        "evaluationDelay": "AfterProvisioning",
        "deployment": {
            "properties": {
                "mode": "incremental",
                "template": {
                    "$schema": "https://schema.management.azure.com/schemas/2015-01-01/deploymentTemplate.json#",
                    "contentVersion": "1.0.0.0",
                    "parameters": {
                        "zoneName": {
                            "type": "string"
                        },
                        "vnetId": {
                            "type": "string"
                        }
                    },
                    "resources": [{
                        "name": "[concat(parameters('zoneName'), '/linkToHub')]",
                        "type": "Microsoft.Network/privateDnsZones/virtualNetworkLinks",
                        "location": "global",
                        "apiVersion": "2020-06-01",
                        "properties": {
                            "registrationEnabled": false,
                            "virtualNetwork": {
                                "id": "[parameters('vnetId')]"
                            }
                        }
                    }]
                },
                "parameters": {
                    "zoneName": {
                        "value": "[field('fullName')]"
                    },
                    "vnetId": {
                        "value": "[parameters('vnetId')]"
                    }
                }
            }
        }
      }
    }
  }
POLICY_RULE


  parameters = <<PARAMETERS
    {
    "vnetId": {
      "type": "String",
      "metadata": {
        "description": "Hub VNET ID",
        "displayName": "Hub VNET ID"
      }
    }
  }
PARAMETERS

}

resource "azurerm_policy_assignment" "policy" {
  name                 = "linkDnsZoneToHub"
  scope                = azurerm_resource_group.spoke.id
  policy_definition_id = azurerm_policy_definition.policy.id
  description          = "linkDnsZoneToHub"
  display_name         = "linkDnsZoneToHub"
  location             = azurerm_resource_group.hub.location
  identity {
    type = "SystemAssigned"
  }

  metadata = <<METADATA
    {
    "category": "General"
    }
METADATA

  parameters = <<PARAMETERS
{
  "vnetId": {
    "value": "${azurerm_virtual_network.hub.id}"
  }
}
PARAMETERS

}


# Policy identity to get permissions to access hub and spoke resources (typically you would rather assign this on MG scope)
resource "azurerm_role_assignment" "policyidentity" {
  scope                = azurerm_resource_group.hub.id
  role_definition_name = "Contributor"
  principal_id         = azurerm_policy_assignment.policy.identity[0].principal_id
}

resource "azurerm_role_assignment" "policyidentityspoke" {
  scope                = azurerm_resource_group.spoke.id
  role_definition_name = "Contributor"
  principal_id         = azurerm_policy_assignment.policy.identity[0].principal_id
}