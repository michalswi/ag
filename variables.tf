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

# rg
variable "rg_name" {
  description = "The name of an existing resource group to create the Application Gateway in."
  type        = string
  default     = ""
}

variable "create_rg" {
  description = "Whether to create a new resource group or use an existing one."
  type        = bool
  default     = false
}

# vnet
variable "create_vnet" {
  description = "Whether to create a new vnet or use an existing one."
  type        = bool
  default     = false
}

variable "vnet_address_space" {
  description = "Address space for the new VNET."
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

# subnet
variable "vnet_name" {
  description = "The name of an existing vnet."
  type        = string
  default     = ""
}

variable "frontend_subnet_id" {
  description = "Application Gateway frontend subnet id."
}

variable "create_subnet" {
  description = "Whether to create a new subnet or use an existing one."
  type        = bool
  default     = false
}

variable "subnet_address_prefixes" {
  description = "Address space for the new subnet."
  type        = list(string)
  default     = ["10.10.1.0/24"]
}

# pip
variable "create_pip" {
  description = "Whether to create a new static public ip or use an existing one."
  type        = bool
  default     = false
}

variable "static_pip_id" {
  description = "Application Gateway static public IP address id."
}

# ag
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
