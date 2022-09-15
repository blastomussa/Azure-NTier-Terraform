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


# Azure Resource Manager provider
provider "azurerm" {
  features {}
  subscription_id            = var.subscription_id
  skip_provider_registration = true
}

# Kubernetes provider credentials
provider "kubernetes" {
  host                   = azurerm_kubernetes_cluster.k8s.kube_config.0.host
  client_certificate     = base64decode(azurerm_kubernetes_cluster.k8s.kube_config.0.client_certificate)
  client_key             = base64decode(azurerm_kubernetes_cluster.k8s.kube_config.0.client_key)
  cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.k8s.kube_config.0.cluster_ca_certificate)
}
