```
locals {
  location         = "East US"
  app_service_fqdn = ["myappservice.azurewebsites.net"]
  tags = {
    Environment = "dev"
    Project     = "dev"
  }
}

resource "azurerm_resource_group" "rg" {
  name     = "<name>"
  location = local.location
  tags     = local.tags
}

# module "vnet" {
#   (...)
# }

# module "static_pip" {
#   (...)
# }

module "azure_app_gateway" {
  source = "git::git@github.com:michalswi/ag.git?ref=main"

  location         = local.location
  app_service_fqdn = local.app_service_fqdn

  rg_name = azurerm_resource_group.rg.name

  frontend_subnet_id = module.vnet.subnet.id
  static_pip_id      = module.static_pip.id

  tags = local.tags
}
```
