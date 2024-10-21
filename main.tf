locals {
  enable_logs = var.enable_logs

  tags                       = var.tags
  name                       = var.name
  rg_name                    = var.rg_name
  log_analytics_workspace_id = var.log_analytics_workspace_id
  location                   = var.location

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

resource "azurerm_monitor_diagnostic_setting" "this" {
  count = local.enable_logs == "true" ? 1 : 0

  name                       = "${local.name}-diag"
  target_resource_id         = azurerm_application_gateway.this.id
  log_analytics_workspace_id = local.log_analytics_workspace_id

  enabled_log {
    category_group = "allLogs"
  }

  # enabled_log {
  #   category = "ApplicationGatewayAccessLog"
  # }

  # enabled_log {
  #   category = "ApplicationGatewayPerformanceLog"
  # }

  # enabled_log {
  #   category = "ApplicationGatewayFirewallLog"
  # }

  metric {
    category = "AllMetrics"
    enabled  = true
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

  # todo
  # https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/application_gateway#host
  # probe {
  #   name                = "probe_${local.name}"
  #   interval            = 30
  #   protocol            = "Https"
  #   path                = "/"
  #   timeout             = 30
  #   unhealthy_threshold = 3
  #   minimum_servers     = 0
  #   # host                                      = <todo>
  #   # pick_host_name_from_backend_http_settings = false

  #   match {
  #     status_code = ["200-499"]
  #   }
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
#   resource_group_name = local.rg_name
#   location            = local.location

#   custom_rules {
#     name      = "Rule1"
#     priority  = 1
#     rule_type = "MatchRule"

#     match_conditions {
#       match_variables {
#         variable_name = "RemoteAddr"
#       }

#       operator           = "IPMatch"
#       negation_condition = false
#       match_values       = ["192.168.1.0/24", "10.0.0.0/24"]
#     }

#     action = "Block"
#   }

#   policy_settings {
#     enabled                     = true
#     mode                        = "Prevention"
#     request_body_check          = true
#     file_upload_limit_in_mb     = 100
#     max_request_body_size_in_kb = 128
#   }

#   managed_rules {
#     exclusion {
#       match_variable          = "RequestHeaderNames"
#       selector                = "x-company-secret-header"
#       selector_match_operator = "Equals"
#     }
#     exclusion {
#       match_variable          = "RequestCookieNames"
#       selector                = "too-tasty"
#       selector_match_operator = "EndsWith"
#     }

#     managed_rule_set {
#       type    = "OWASP"
#       version = "3.2"
#       rule_group_override {
#         rule_group_name = "REQUEST-920-PROTOCOL-ENFORCEMENT"
#         rule {
#           id      = "920300"
#           enabled = true
#           action  = "Log"
#         }

#         rule {
#           id      = "920440"
#           enabled = true
#           action  = "Block"
#         }
#       }
#     }
#   }
# }
