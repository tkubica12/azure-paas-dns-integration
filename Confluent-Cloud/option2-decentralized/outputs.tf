output "paasSubnetId" {
  value = azurerm_subnet.spokepaas.id
}

output "client_id" {
  value = azuread_application.sp.application_id
}

output "client_secret" {
  value     = azuread_service_principal_password.sp.value
  sensitive = true
}

output "object_id" {
  value = azuread_service_principal.sp.id
}

output "hubVnetId" {
  value = azurerm_virtual_network.hub.id
}