variable "enable_ag" {
  default = false
  type    = bool
}

variable "tags" {
  description = "Tags to apply to the Application Gateway."
  type        = map(string)
  default     = {}
}

variable "name" {
  description = "Prefix"
  default     = "1ad"
}

variable "rg_name" {
  description = "The name of the resource group to create the Application Gateway in."
  type        = string
}

variable "location" {
  description = "The Azure region where the resources will be created."
  type        = string
}

variable "ag_frontend_subnet_id" {
  description = "Application Gateway frontend subnet id."
}

variable "ag_static_pip_id" {
  description = "Application Gateway static public IP address id."
}

variable "app_service_fqdn" {
  description = "The list of FQDNs of the App Service backend."
  type        = set(string)
  default     = []
}
