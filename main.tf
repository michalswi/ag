locals {
  name     = var.name
  rg_name  = var.rg_name
  location = var.location
  tags     = var.tags

  agw_public_ip  = var.agw_public_ip
  agw_subnet     = var.agw_subnet
  agw_private_ip = cidrhost(var.agw_subnet.address_prefixes[0], 16)

  sku_name     = var.sku_name
  sku_tier     = var.sku_tier
  max_capacity = var.max_capacity

  frontend_public_ip_config  = "appGwPublicFrontendIp"
  frontend_private_ip_config = "appGwPrivateFrontendIp"

  backend_address_pool_name  = "backend-appservice-list"
  backend_fqdns              = var.backend_fqdns
  backend_http_settings_name = "backend-settings"

  http_listener_name = "https-listener"

  frontend_ports = {
    http = {
      port = 80
      name = "${var.name}-ag-fp-80"
    },
    https = {
      port = 443
      name = "${var.name}-ag-fp-443"
    }
  }
}

# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/application_gateway
resource "azurerm_application_gateway" "this" {
  count = var.enable_ag ? 1 : 0

  name                = "${local.name}-ag"
  resource_group_name = local.rg_name
  location            = local.location

  sku {
    name = local.sku_name
    tier = local.sku_tier
  }

  autoscale_configuration {
    min_capacity = 1
    max_capacity = local.max_capacity
  }

  gateway_ip_configuration {
    name      = "appGatewayIpConfig"
    subnet_id = local.agw_subnet.id
  }

  # public
  frontend_ip_configuration {
    name                 = local.frontend_public_ip_config
    public_ip_address_id = local.public_ip.id
  }

  # private
  frontend_ip_configuration {
    name                          = local.frontend_private_ip_config
    private_ip_address_allocation = "Static"
    private_ip_address            = local.agw_private_ip
    subnet_id                     = local.agw_subnet.id
  }

  frontend_port {
    name = local.frontend_ports.http.name
    port = local.frontend_ports.http.port
  }

  frontend_port {
    name = local.frontend_ports.https.name
    port = local.frontend_ports.https.port
  }

  # todo
  # dynamic "ssl_certificate" {}

  backend_address_pool {
    name  = local.backend_address_pool_name
    fqdns = local.backend_fqdns
  }
  # dynamic "backend_address_pool" {
  #   for_each = { for key, value in local.backend_fqdns : key => value }

  #   content {
  #     name  = "${local.backend_address_pool_name}_${each.key}"
  #     fqdns = [each.value]
  #   }
  # }

  # todo
  backend_http_settings {
    name                  = local.backend_http_settings_name
    port                  = 443
    protocol              = "Https"
    cookie_based_affinity = "Disabled"
    request_timeout       = 20
    # pick_host_name_from_backend_address = true
  }

  # todo
  http_listener {
    name                           = local.http_listener_name
    frontend_ip_configuration_name = local.frontend_public_ip_config
    frontend_port_name             = local.frontend_ports.https.name
    protocol                       = "Https"
    # ssl_certificate_name = <todo>
    # firewall_policy_id = <todo>
  }

  # todo
  # connect frontend and backend pool
  # https://docs.microsoft.com/en-us/azure/application-gateway/quick-create-portal#configuration-tab
  request_routing_rule {
    name                       = "appGatewayRoutingRule"
    rule_type                  = "Basic"
    http_listener_name         = local.http_listener_name
    backend_address_pool_name  = local.backend_address_pool_name
    backend_http_settings_name = local.backend_http_settings_name
  }

  # todo
  # probe {
  # }

  tags = local.tags
}
