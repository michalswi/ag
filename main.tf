locals {
  frontend_ip_configuration_name = "${var.name}-ag-frontend-ipconfig"
  frontend_port_name_80          = "${var.name}-ag-fp-80"
  frontend_port_name_443         = "${var.name}-ag-fp-443"
  http_listener_name             = "${var.name}-ag-httplstn"
  backend_address_pool_name      = "${var.name}-ag-bap-appservice"
  backend_http_settings_name     = "${var.name}-ag-backend-settings"
  rg_name                        = var.create_rg ? azurerm_resource_group.rg[0].name : var.rg_name
  vnet_name                      = var.create_vnet ? azurerm_virtual_network.vnet[0].name : var.vnet_name
  frontend_subnet_id             = var.create_subnet ? azurerm_subnet.frontend_subnet[0].id : var.frontend_subnet_id
  static_pip_id                  = var.create_pip ? azurerm_public_ip.pip[0].id : var.static_pip_id
}

resource "azurerm_resource_group" "rg" {
  count = var.create_rg ? 1 : 0

  name     = "${var.name}-rg"
  location = var.location
}

resource "azurerm_virtual_network" "vnet" {
  count = var.create_vnet ? 1 : 0

  name                = "${var.name}-vnet"
  resource_group_name = local.rg_name
  location            = var.location
  address_space       = var.vnet_address_space
}

resource "azurerm_subnet" "frontend_subnet" {
  count = var.create_subnet ? 1 : 0

  name                 = "${var.name}-frontend-subnet"
  resource_group_name  = local.rg_name
  virtual_network_name = local.vnet_name
  address_prefixes     = var.subnet_address_prefixes
}

resource "azurerm_public_ip" "pip" {
  count = var.create_pip ? 1 : 0

  name                = "${var.name}-pip"
  resource_group_name = local.rg_name
  location            = var.location
  # allocation_method   = "Dynamic"
  allocation_method = "Static"
  sku               = "Standard"
}

# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/application_gateway
resource "azurerm_application_gateway" "appgw" {
  count = var.enable_ag ? 1 : 0

  name                = "${var.name}-ag"
  resource_group_name = local.rg_name
  location            = var.location

  sku {
    name     = var.sku_name
    tier     = var.sku_tier
    capacity = var.sku_capacity
  }

  gateway_ip_configuration {
    name      = "${var.name}-ag-gateway-ipconfig"
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
    fqdns = var.app_service_fqdn
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

  tags = var.tags
}
