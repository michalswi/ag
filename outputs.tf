output "application_gateway_id" {
  description = "The ID of the Application Gateway."
  value       = azurerm_application_gateway.main[0].id
}

output "frontend_ip_configuration_id" {
  description = "The ID of the frontend IP configuration."
  value       = azurerm_application_gateway.main[0].frontend_ip_configuration[0].id
}
