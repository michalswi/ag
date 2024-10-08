output "application_gateway_id" {
  description = "The ID of the Application Gateway."
  value       = azurerm_application_gateway.main.id
}

output "frontend_ip_configuration_id" {
  description = "The ID of the frontend IP configuration."
  value       = azurerm_application_gateway.main.frontend_ip_configuration[0].id
}
