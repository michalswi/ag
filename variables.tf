variable "enable_ag" {
  default = true
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

variable "location" {
  description = "The Azure region where the resources will be created."
  type        = string
}

variable "rg_name" {
  description = "The name of an existing resource group to create the Application Gateway in."
  type        = string
  default     = ""
}

variable "frontend_subnet_id" {
  description = "Application Gateway frontend subnet id."
}

variable "static_pip_id" {
  description = "Application Gateway static public IP address id."
}

variable "app_service_fqdn" {
  description = "The list of FQDNs of the App Service backend."
  type        = list(string)
  default     = []
}

variable "sku_name" {
  description = " The Name of the SKU to use for this Application Gateway."
  type        = string
  default     = "Standard_v2"
}

variable "sku_tier" {
  description = "The Tier of the SKU to use for this Application Gateway."
  type        = string
  default     = "Standard_v2"
}

variable "sku_capacity" {
  description = "The Capacity of the SKU to use for this Application Gateway."
  type        = number
  default     = 2
}
