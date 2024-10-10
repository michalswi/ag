```
locals {
  location         = "East US"
  app_service_fqdn = ["myappservice.azurewebsites.net"]
  tags = {
    Environment = "dev"
    Project     = "dev"
  }
}

module "rg" {
  (...)
}

module "vnet" {
  (...)
}

module "static_pip" {
  (...)
}

module "azure_app_gateway" {
  source = "git::git@github.com:michalswi/ag.git?ref=main"

  location         = local.location
  app_service_fqdn = local.app_service_fqdn

  rg_name            = module.rg.name
  frontend_subnet_id = module.vnet.subnet.id
  static_pip_id      = module.static_pip.id

  tags = local.tags
}
```
