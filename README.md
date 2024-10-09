```
module "azure_app_gateway" {
  source = "git::git@github.com:michalswi/ag.git?ref=main"

  location              = "East US"
  app_service_fqdn      = ["myappservice.azurewebsites.net"]

  # [rg exists]
  rg_name               = "my-resource-group"
  # [rg doesn't exist]
  /*
  create_rg             = true
  */

  # [subnet exists]
  frontend_subnet_id = "todo"
  # [subnet doesn't exists / vnet does exist]
  /*
  vnet_name = "todo"
  create_subnet         = true
  subnet_address_prefixes = ["10.10.1.0/24"]
  */
  # [subnet doesn't exists / vnet doesn't exist]
  /*
  create_vnet = true
  vnet_address_space    = ["10.0.0.0/16"]
  create_subnet         = true
  subnet_address_prefixes = ["10.10.1.0/24"]
  */
  
  # [pip exists]
  static_pip_id      = "todo"
  # [pip doesn't exist]
  /*
  create_pip = true
  */

  tags = {
    Environment = "dev"
    Project     = "dev"
  }
}
```
