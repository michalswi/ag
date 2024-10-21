variable "enable_logs" {
  description = "Enable Azure Monitor diagnostics."
  type        = bool
  default     = true
}

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

variable "agw_subnet_address_prefixes" {
  description = "Application Gateway subnet address prefixes."
  type        = list(string)
}

variable "agw_subnet_id" {
  description = "Application Gateway subnet id."
  type        = string
}

variable "agw_public_ip_id" {
  description = "Application Gateway static public IP address ID."
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
  default     = "Standard_v2"
  # default     = "WAF_v2"
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
  description = "List of TLS/SSL Certificate names."
  type        = list(string)
  default     = []
}

variable "log_analytics_workspace_id" {
  description = "Log Analytics workspace id."
  type        = string
  default     = ""
}
