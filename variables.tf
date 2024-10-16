variable "tags" {
  description = "List of tags."
  type        = map(string)
  default     = {}
}

variable "name" {
  description = "Resource name prefix."
  default     = "oneadkv"
}

variable "location" {
  description = "The Azure region where the resources will be created."
  type        = string
}

variable "rg_name" {
  description = "The name of an existing resource group to create the resource in."
  type        = string
  default     = ""
}

variable "agw_subnet" {
  description = "Application Gateway subnet."
  type        = string
}

variable "agw_public_ip" {
  description = "Application Gateway static public IP address."
  type        = string
}

variable "backend_fqdns" {
  description = "The list of FQDNs of the App Service backend."
  type        = list(string)
  default     = []
}

variable "sku_name" {
  description = "The Name of the SKU to use for this Application Gateway."
  type        = string
  default     = "Standard_v2"
  # default     = "WAF_v2"
}

variable "sku_tier" {
  description = "The Tier of the SKU to use for this Application Gateway."
  type        = string
  default     = "WAF_v2"
  # default     = "Standard_v2"
}

variable "max_capacity" {
  description = "Maximum capacity for autoscaling."
  type        = number
  default     = 3
}

variable "key_vault_id" {
  description = "Existing Key Vault id."
  type        = string
}

variable "certificate_refs" {
  description = "Certificates names."
  type        = list(string)
}
