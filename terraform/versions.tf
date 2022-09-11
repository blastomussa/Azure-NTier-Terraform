terraform {
  required_version = ">= 1.2"
  required_providers {
    azurerm = {
      version = "~> 3.22.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.0.1"
    }
  }
}
