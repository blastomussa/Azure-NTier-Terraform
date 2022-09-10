# https://learn.hashicorp.com/tutorials/terraform/kubernetes-provider?in=terraform/kubernetes
# https://github.com/hashicorp/learn-terraform-deploy-nginx-kubernetes-provider/blob/aks/kubernetes.tf
# how do I deploy custom docker image via Azure Container Registry; service principal?

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.0.2"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.0.1"
    }
  }
}

data "terraform_remote_state" "aks" {
  backend = "local"

  config = {
    path = "../cluster/terraform.tfstate"
  }
}

# Retrieve AKS cluster information
provider "azurerm" {
  features {}
}
