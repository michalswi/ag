```
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
  
  location           = "East US"
  app_service_fqdn   = ["myappservice.azurewebsites.net"]

  rg_name            = module.rg.name
  frontend_subnet_id = module.vnet.subnet.id
  static_pip_id      = module.static_pip.id

  tags = {
    Environment = "dev"
    Project     = "dev"
  }
}
```
