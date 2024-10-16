locals {
  name     = var.name
  rg_name  = var.rg_name
  location = var.location
  tags     = var.tags

  key_vault_id = var.key_vault_id

  certificate_refs = var.certificate_refs

  agw_public_ip_id = var.agw_public_ip_id
  agw_subnet_id    = var.agw_subnet_id
  agw_private_ip   = cidrhost(var.agw_subnet_address_prefixes[0], 16)

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

# RBAC or MI - todo
resource "azurerm_role_assignment" "this" {
  principal_id         = azurerm_application_gateway.this.identity[0].principal_id
  role_definition_name = "Key Vault Certificates User"
  scope                = local.key_vault_id
}
# resource "azurerm_user_assigned_identity" "this" {
#   name                = "${local.name}-mig"
#   resource_group_name = local.rg_name
#   location            = local.location
#   tags                = local.tags
# }

# ssl certificates
data "azurerm_key_vault_certificate" "this" {
  for_each     = { for cert in local.certificate_refs : cert => cert }
  key_vault_id = local.key_vault_id
  name         = each.value
}

# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/application_gateway
resource "azurerm_application_gateway" "this" {
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
    subnet_id = local.agw_subnet_id
  }

  # public
  frontend_ip_configuration {
    name                 = local.frontend_public_ip_config
    public_ip_address_id = local.agw_public_ip_id
  }

  # private
  frontend_ip_configuration {
    name                          = local.frontend_private_ip_config
    private_ip_address_allocation = "Static"
    private_ip_address            = local.agw_private_ip
    subnet_id                     = local.agw_subnet_id
  }

  frontend_port {
    name = local.frontend_ports.http.name
    port = local.frontend_ports.http.port
  }

  frontend_port {
    name = local.frontend_ports.https.name
    port = local.frontend_ports.https.port
  }

  backend_address_pool {
    name  = local.backend_address_pool_name
    fqdns = local.backend_fqdns
  }

  # todo
  backend_http_settings {
    name                  = local.backend_http_settings_name
    port                  = 443
    protocol              = "Https"
    cookie_based_affinity = "Disabled"
    request_timeout       = 20
    # pick_host_name_from_backend_address = true
  }

  http_listener {
    name                           = local.http_listener_name
    frontend_ip_configuration_name = local.frontend_public_ip_config
    frontend_port_name             = local.frontend_ports.https.name
    protocol                       = "Https"
    # ssl_certificate_name = <todo>
    # firewall_policy_id = azurerm_web_application_firewall_policy.this.id - todo

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
    # priority = 10/100?  - todo
  }

  # todo - MI or RBAC
  identity {
    type = "SystemAssigned"
  }

  # waf - todo
  # firewall_policy_id = azurerm_web_application_firewall_policy.this.id

  # ssl_certificate - todo
  dynamic "ssl_certificate" {
    for_each = data.azurerm_key_vault_certificate.this

    content {
      name                = ssl_certificate.key
      key_vault_secret_id = ssl_certificate.value.secret_id
    }
  }

  # dynamic "ssl_certificate" {
  #   for_each = { for cert in local.ssl_certificate : cert.name => cert.key_vault_secret_id }

  #   content {
  #     name = ssl_certificate.key
  #     key_vault_secret_id = ssl_certificate.value
  #   }
  # }

  # todo
  # https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/application_gateway#host
  # probe {
  # }

  tags = local.tags
}

# todo
# waf
# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/web_application_firewall_policy
# resource "azurerm_web_application_firewall_policy" "this" {
#   name                = "platform_base_firewall_policy"
#   (...)
# }
