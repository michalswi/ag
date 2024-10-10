locals {
  name               = var.name
  rg_name            = var.rg_name
  location           = var.location
  frontend_subnet_id = var.frontend_subnet_id
  static_pip_id      = var.static_pip_id
  app_service_fqdn   = var.app_service_fqdn
  tags               = var.tags
  sku_name           = var.sku_name
  sku_tier           = var.sku_tier
  sku_capacity       = var.sku_capacity

  frontend_ip_configuration_name = "${var.name}-ag-frontend-ipconfig"
  frontend_port_name_80          = "${var.name}-ag-fp-80"
  frontend_port_name_443         = "${var.name}-ag-fp-443"
  http_listener_name             = "${var.name}-ag-httplstn"
  backend_address_pool_name      = "${var.name}-ag-bap-appservice"
  backend_http_settings_name     = "${var.name}-ag-backend-settings"
}

# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/application_gateway
resource "azurerm_application_gateway" "this" {
  count = var.enable_ag ? 1 : 0

  name                = "${local.name}-ag"
  resource_group_name = local.rg_name
  location            = local.location

  sku {
    name     = local.sku_name
    tier     = local.sku_tier
    capacity = local.sku_capacity
  }

  gateway_ip_configuration {
    name      = "${local.name}-ag-gateway-ipconfig"
    subnet_id = local.frontend_subnet_id
  }

  frontend_ip_configuration {
    name                 = local.frontend_ip_configuration_name
    public_ip_address_id = local.static_pip_id
  }

  frontend_port {
    name = local.frontend_port_name_80
    port = 80
  }

  frontend_port {
    name = local.frontend_port_name_443
    port = 443
  }

  backend_address_pool {
    name  = local.backend_address_pool_name
    fqdns = local.app_service_fqdn
  }

  backend_http_settings {
    name                  = local.backend_http_settings_name
    cookie_based_affinity = "Disabled"
    port                  = 80
    protocol              = "Http"
    request_timeout       = 5
    # path = "/path1/"
    # pick_host_name_from_backend_address = true
  }

  http_listener {
    name                           = local.http_listener_name
    frontend_ip_configuration_name = local.frontend_ip_configuration_name
    frontend_port_name             = local.frontend_port_name_80
    protocol                       = "Http"
  }

  # connect frontend and backend pool
  # https://docs.microsoft.com/en-us/azure/application-gateway/quick-create-portal#configuration-tab
  request_routing_rule {
    name                       = "appGatewayRoutingRule"
    rule_type                  = "Basic"
    http_listener_name         = local.http_listener_name
    backend_address_pool_name  = local.backend_address_pool_name
    backend_http_settings_name = local.backend_http_settings_name
  }

  tags = local.tags
}
