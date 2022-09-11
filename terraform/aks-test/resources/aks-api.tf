# THIS WORKS!!!
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

# set tfstate file as tfstate of cluster's directory
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


data "azurerm_kubernetes_cluster" "cluster" {
  name                = data.terraform_remote_state.aks.outputs.kubernetes_cluster_name
  resource_group_name = data.terraform_remote_state.aks.outputs.resource_group_name
}

provider "kubernetes" {
  host = data.azurerm_kubernetes_cluster.cluster.kube_config.0.host

  client_certificate     = base64decode(data.azurerm_kubernetes_cluster.cluster.kube_config.0.client_certificate)
  client_key             = base64decode(data.azurerm_kubernetes_cluster.cluster.kube_config.0.client_key)
  cluster_ca_certificate = base64decode(data.azurerm_kubernetes_cluster.cluster.kube_config.0.cluster_ca_certificate)
}


# DEPLOYMENT
resource "kubernetes_deployment" "api" {
  metadata {
    name = "flask-api"
    labels = {
      App = "FlaskAPI"
    }
  }

  spec {
    replicas = 2
    selector {
      match_labels = {
        App = "FlaskAPI"
      }
    }
    template {
      metadata {
        labels = {
          App = "FlaskAPI"
        }
      }
      spec {
        container {
          image = "testcontainer12359.azurecr.io/backend:ca1" #<<<<<<<<<<<<<<<<<<<-----------THIS NEEDS TO BE DYNAMIC
          name  = "api"

          port {
            container_port = 80
          }

          resources {
            limits = {
              cpu    = "0.5"
              memory = "512Mi"
            }
            requests = {
              cpu    = "250m"
              memory = "50Mi"
            }
          }
        }
      }
    }
  }
}


# Expose pod with service
resource "kubernetes_service" "api" {
  metadata {
    name = "flask-api"
  }
  spec {
    selector = {
      App = kubernetes_deployment.api.spec.0.template.0.metadata[0].labels.App
    }
    port {
      port        = 80
      target_port = 80
    }

    type = "LoadBalancer"
  }
}

output "lb_ip" {
  value = kubernetes_service.api.status.0.load_balancer.0.ingress.0.ip
}
