


# Service Principal to simulate spoke user
data "azuread_client_config" "current" {}

resource "azuread_application" "sp" {
  display_name = "tomaskubicaspokeusersimulate"
  owners       = [data.azuread_client_config.current.object_id]
}

resource "azuread_service_principal" "sp" {
  application_id = azuread_application.sp.application_id
  owners                       = [data.azuread_client_config.current.object_id]
}

resource "azuread_service_principal_password" "sp" {
  service_principal_id = azuread_service_principal.sp.id
}

# Role definition (to enable spoke user join DNS zone)
data "azurerm_subscription" "primary" {
}

resource "azurerm_role_definition" "dnsjoin" {
  name        = "dnsjoin"
  scope       = data.azurerm_subscription.primary.id
  description = "Custom role that allows joing DNS and read on RG (this is currently needed for CLI to work)"

  permissions {
    actions     = [
         "Microsoft.Network/privateDnsZones/join/action",
         "Microsoft.Network/privateDnsZones/read",
         "Microsoft.Resources/subscriptions/resourceGroups/read"
    ]
    not_actions = []
  }

  assignable_scopes = [
    data.azurerm_subscription.primary.id
  ]
}