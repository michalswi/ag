locals {
  name     = var.name
  rg_name  = var.rg_name
  location = var.location
  tags     = var.tags

  key_vault_id = var.key_vault_id

  certificate_refs = length(var.certificate_refs) > 0 ? concat(["default"], var.certificate_refs) : ["default"]
  # certificate_refs = length(var.certificate_refs) > 0 ? var.certificate_refs : ["default"]
  # todo - change it
  signed_cert = "ag-ssl-cert"

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

# ssl certificate
data "azurerm_key_vault_certificate" "this" {
  for_each = { for cert in local.certificate_refs : cert => cert }

  key_vault_id = local.key_vault_id
  name         = each.value
}

# RBAC
resource "azurerm_role_assignment" "this" {
  principal_id         = azurerm_user_assigned_identity.this.principal_id
  role_definition_name = "Key Vault Secrets User"
  scope                = local.key_vault_id
}

resource "azurerm_user_assigned_identity" "this" {
  name                = "${local.name}-identity"
  resource_group_name = local.rg_name
  location            = local.location
}

resource "azurerm_key_vault_access_policy" "this" {
  key_vault_id = local.key_vault_id
  tenant_id    = azurerm_user_assigned_identity.this.tenant_id
  object_id    = azurerm_user_assigned_identity.this.principal_id
  certificate_permissions = [
    "Get",
    "List"
  ]
  secret_permissions = [
    "Get",
    "List"
  ]
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

  backend_http_settings {
    name                  = local.backend_http_settings_name
    port                  = 443
    protocol              = "Https"
    cookie_based_affinity = "Disabled"
    request_timeout       = 20
    # trusted_root_certificate_names      = azurerm_key_vault_access_policy.this
    # pick_host_name_from_backend_address = true
  }

  http_listener {
    name                           = local.http_listener_name
    frontend_ip_configuration_name = local.frontend_public_ip_config
    frontend_port_name             = local.frontend_ports.https.name
    protocol                       = "Https"
    ssl_certificate_name           = try(data.azurerm_key_vault_certificate.this[local.signed_cert].name, "default")
    # todo
    # firewall_policy_id = azurerm_web_application_firewall_policy.this.id - todo

  }

  dynamic "ssl_certificate" {
    for_each = data.azurerm_key_vault_certificate.this

    content {
      name                = ssl_certificate.key
      key_vault_secret_id = ssl_certificate.value.secret_id
    }

  }
  # ssl_certificate {
  #   name = try(data.azurerm_key_vault_certificate.this["ag-ssl-cert"].name, "default")
  #   key_vault_secret_id = try(
  #     data.azurerm_key_vault_certificate.this["ag-ssl-cert"].secret_id,
  #     data.azurerm_key_vault_certificate.this["default"].secret_id
  #   )
  # }

  # todo
  # connect frontend and backend pool
  # https://docs.microsoft.com/en-us/azure/application-gateway/quick-create-portal#configuration-tab
  request_routing_rule {
    name                       = "appGatewayRoutingRule"
    rule_type                  = "Basic"
    http_listener_name         = local.http_listener_name
    backend_address_pool_name  = local.backend_address_pool_name
    backend_http_settings_name = local.backend_http_settings_name
    priority                   = 100
  }

  identity {
    type = "UserAssigned"
    identity_ids = [
      azurerm_user_assigned_identity.this.id,
    ]
  }

  # waf - todo
  # firewall_policy_id = azurerm_web_application_firewall_policy.this.id

  # probe - todo
  # https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/application_gateway#host
  # probe {
  # }

  tags = local.tags

  depends_on = [
    azurerm_key_vault_access_policy.this,
    azurerm_role_assignment.this,
  ]
}

# waf - todo
# uncomment >> variables.tf
# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/web_application_firewall_policy
# resource "azurerm_web_application_firewall_policy" "this" {
#   name                = "platform_base_firewall_policy"
#   (...)
# }
