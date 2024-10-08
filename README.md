```
module "azure_app_gateway" {
  source = "git::git@github.com:michalswi/ag.git?ref=main"

  enable_ag = true

  rg_name               = "my-resource-group"
  location              = "East US"
  ag_frontend_subnet_id = "todo"
  ag_static_pip_id      = "todo"
  app_service_fqdn      = ["myappservice.azurewebsites.net"]

  tags = {
    Environment = "dev"
    Project     = "dev"
  }
}
```
