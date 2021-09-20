


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

resource "azurerm_role_assignment" "rgcontributor" {
  scope                = azurerm_resource_group.spoke.id
  role_definition_name = "Contributor"
  principal_id         = azuread_service_principal.sp.object_id
}

