# backend_address_pool_name
locals {
  backend_address_pool_name      = "${var.ag_vnet_name}-beap"
  frontend_port_name             = "${var.ag_vnet_name}-feport"
  frontend_ip_configuration_name = "${var.ag_vnet_name}-feip"
  http_setting_name              = "${var.ag_vnet_name}-be-htst"
  listener_name                  = "${var.ag_vnet_name}-httplstn"
  request_routing_rule_name      = "${var.ag_vnet_name}-rqrt"
  redirect_configuration_name    = "${var.ag_vnet_name}-rdrcfg"
}

# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/application_gateway
resource "azurerm_application_gateway" "main" {
  count = var.enable_ag ? 1 : 0

  name                = "${var.name}-ag"
  resource_group_name = var.rg_name
  location            = var.rg_location

  sku {
    name     = "Standard_v2"
    tier     = "Standard_v2"
    capacity = 2
  }

  gateway_ip_configuration {
    name      = "${var.name}-ag-ip-config"
    subnet_id = var.ag_frontend_subnet_id
  }

  frontend_port {
    name = local.frontend_port_name
    port = 80
  }

  frontend_port {
    name = "httpsPort"
    port = 443
  }

  frontend_ip_configuration {
    name                 = local.frontend_ip_configuration_name
    public_ip_address_id = var.ag_frontend_subnet_id
  }

  # backend_address_pool_name
  backend_address_pool {
    name = local.backend_address_pool_name
  }

  backend_http_settings {
    name                  = local.http_setting_name
    cookie_based_affinity = "Disabled"
    # path = "/path1/"
    # port = 8080
    port            = 80
    protocol        = "Http"
    request_timeout = 5
  }

  http_listener {
    name                           = local.listener_name
    frontend_ip_configuration_name = local.frontend_ip_configuration_name
    frontend_port_name             = local.frontend_port_name
    protocol                       = "Http"
  }

  # connect frontend and backend pool
  # https://docs.microsoft.com/en-us/azure/application-gateway/quick-create-portal#configuration-tab
  request_routing_rule {
    name                       = local.request_routing_rule_name
    rule_type                  = "Basic"
    http_listener_name         = local.listener_name
    backend_address_pool_name  = local.backend_address_pool_name
    backend_http_settings_name = local.http_setting_name
  }
}