variable "enable_ag" {
  default = false
  type    = bool
}

variable "name" {
  default = "1ad"
}

variable "location" {
  default = "westeurope"
}

variable "rg_name" {
  description = "Resource Group name."
}

variable "rg_location" {
  description = "Resource Group location."
}

variable "ag_vnet_name" {
  description = "Application Gateway VNet name."
}

variable "ag_frontend_subnet_id" {
  description = "Application Gateway frontend subnet id."
}

variable "ag_static_pip_id" {
  description = "Application Gateway static public IP address id."
}
