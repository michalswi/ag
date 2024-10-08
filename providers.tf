provider "azurerm" {
  features {}
}

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=4.4.0"
      # version = "~>4.0"
    }
  }
  # terraform version
  required_version = "~>1.5.0"
}
