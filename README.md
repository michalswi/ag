```
locals {
  location         = "East US"
  backend_fqdns = ["myappservice.azurewebsites.net"]
  tags = {
    Environment = "dev"
    Project     = "dev"
  }
}

resource "azurerm_resource_group" "ag_rg" {
  name     = "<name>"
  location = local.location
  tags     = local.tags
}

# module "vnet" {
#   (...)
# }

# module "static_pip" {
#  (...)
#  allocation_method    = "Static"
#  sku                  = "Standard"
#  zones                = var.default_availability_zones
#  ddos_protection_mode = "Enabled"
# }


module "azure_app_gateway" {
  source = "git::git@github.com:michalswi/ag.git?ref=main"

  location         = local.location
  backend_fqdns = local.backend_fqdns

  rg_name = azurerm_resource_group.ag_rg.name

  agw_subnet = module.vnet.subnet
  agw_public_ip      = module.static_pip

  tags = local.tags
}
```
