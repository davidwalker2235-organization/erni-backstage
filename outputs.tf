output "backstage_service_principal_object_id" {
  value = azuread_service_principal.service_principal.object_id
}

output "backstage_service_principal_id" {
  value = azurerm_app_service.backstage_app.identity[0].principal_id
}

output "backstage_app_outbound_ips" {
  value = azurerm_app_service.backstage_app.outbound_ip_addresses
}

output "backstage_rg_name" {
  value = azurerm_resource_group.backstage_rg.name
}

output "backstage_postgresql_name" {
  value = azurerm_postgresql_server.backstage_postgresql.name
}