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


# Create Resource Group
resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.resource_group_location
}


# Create VNet and subnets
resource "azurerm_virtual_network" "vnet" {
  name                = var.vnet_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = ["10.0.0.0/16"]
  depends_on          = [azurerm_resource_group.rg]
}


resource "azurerm_subnet" "gateway" {
  name                 = "gateway"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
  depends_on           = [azurerm_virtual_network.vnet]
}


resource "azurerm_subnet" "backend" {
  name                 = "backend"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.3.0/24"]
  depends_on           = [azurerm_virtual_network.vnet]
}


resource "azurerm_subnet" "frontend" {
  name                 = "frontend"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.2.0/24"]

  delegation {
    name = "delegation"

    service_delegation { //Container Instance REQUIRES delegation
      name    = "Microsoft.ContainerInstance/containerGroups"
      actions = ["Microsoft.Network/virtualNetworks/subnets/action", "Microsoft.Network/virtualNetworks/subnets/join/action", "Microsoft.Network/virtualNetworks/subnets/prepareNetworkPolicies/action"]
    }
  }
  depends_on = [azurerm_virtual_network.vnet]
}


# Network Profile for private IP address of container instance
resource "azurerm_network_profile" "frontendprofile" {
  name                = "frontendprofile"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  container_network_interface {
    name = "frontendnic"

    ip_configuration {
      name      = "frontendipconfig"
      subnet_id = azurerm_subnet.frontend.id
    }
  }
  depends_on = [azurerm_subnet.frontend]
}


# Public ip for Application Gateway
resource "azurerm_public_ip" "gateway-pip" {
  name                = "gateway-pip"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  allocation_method   = "Static"
  sku                 = "Standard"
}


# since these variables are re-used - a locals block makes this more maintainable
locals {
  backend_address_pool_name      = "${azurerm_virtual_network.vnet.name}-beap"
  frontend_port_name             = "${azurerm_virtual_network.vnet.name}-feport"
  frontend_ip_configuration_name = "${azurerm_virtual_network.vnet.name}-feip"
  http_setting_name              = "${azurerm_virtual_network.vnet.name}-be-htst"
  listener_name                  = "${azurerm_virtual_network.vnet.name}-httplstn"
  request_routing_rule_name      = "${azurerm_virtual_network.vnet.name}-rqrt"
  redirect_configuration_name    = "${azurerm_virtual_network.vnet.name}-rdrcfg"
}


# Create Application Gateway
resource "azurerm_application_gateway" "gateway" {
  name                = "test-appgateway"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  sku {
    name = "Standard_v2"
    tier = "Standard_v2"
  }

  autoscale_configuration {
    min_capacity = 0
    max_capacity = 10
  }

  gateway_ip_configuration {
    name      = "my-gateway-ip-configuration"
    subnet_id = azurerm_subnet.gateway.id
  }

  frontend_port {
    name = local.frontend_port_name
    port = 80
  }

  frontend_ip_configuration {
    name                 = local.frontend_ip_configuration_name
    public_ip_address_id = azurerm_public_ip.gateway-pip.id
  }

  backend_address_pool {
    name         = local.backend_address_pool_name
    ip_addresses = [azurerm_container_group.frontend.ip_address]
  }

  backend_http_settings {
    name                  = local.http_setting_name
    cookie_based_affinity = "Disabled"
    port                  = 80
    protocol              = "Http"
    request_timeout       = 60
  }

  http_listener {
    name                           = local.listener_name
    frontend_ip_configuration_name = local.frontend_ip_configuration_name
    frontend_port_name             = local.frontend_port_name
    protocol                       = "Http"
  }

  request_routing_rule {
    name                       = local.request_routing_rule_name
    rule_type                  = "Basic"
    http_listener_name         = local.listener_name
    backend_address_pool_name  = local.backend_address_pool_name
    backend_http_settings_name = local.http_setting_name
    priority                   = 1
  }
  depends_on = [azurerm_container_group.frontend, azurerm_subnet.gateway, azurerm_public_ip.gateway-pip]
}


# Create Azure Container Registry
resource "azurerm_container_registry" "acr" {
  name                = var.container_registry_name
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "Basic"
  admin_enabled       = true # required
  depends_on          = [azurerm_resource_group.rg]
}


# Build Docker image for backend API with ACR task
resource "azurerm_container_registry_task" "backendtask" {
  name                  = "backend-task"
  container_registry_id = azurerm_container_registry.acr.id
  platform {
    os = "Linux"
  }
  docker_step {
    dockerfile_path      = "backend/Dockerfile"
    context_path         = "https://github.com/blastomussa/Azure-NTier-Terraform.git#master"
    context_access_token = var.github_pat
    image_names          = ["backend:{{.Run.ID}}"]
  }
  source_trigger {
    name           = "github-trigger"
    events         = ["commit"]
    repository_url = "https://github.com/blastomussa/Azure-NTier-Terraform"
    source_type    = "Github"

    authentication {
      token      = var.github_pat
      token_type = "PAT"
    }
  }
  depends_on = [azurerm_container_registry.acr]
}


# Run the backendtask manually
resource "azurerm_container_registry_task_schedule_run_now" "backendbuild" {
  container_registry_task_id = azurerm_container_registry_task.backendtask.id
}



# Build Docker image for frontend API with ACR task
resource "azurerm_container_registry_task" "frontendtask" {
  name                  = "frontend-task"
  container_registry_id = azurerm_container_registry.acr.id
  platform {
    os = "Linux"
  }
  docker_step {
    dockerfile_path      = "frontend/Dockerfile" //this might need to be changed
    context_path         = "https://github.com/blastomussa/Azure-NTier-Terraform.git#master"
    context_access_token = var.github_pat
    image_names          = ["frontend:{{.Run.ID}}"]
  }
  source_trigger {
    name           = "github-trigger"
    events         = ["commit"]
    repository_url = "https://github.com/blastomussa/Azure-NTier-Terraform"
    source_type    = "Github"

    authentication {
      token      = var.github_pat
      token_type = "PAT"
    }
  }
  depends_on = [azurerm_container_registry.acr]
}


# Run the frontendtask manually
resource "azurerm_container_registry_task_schedule_run_now" "frontendbuild" {
  container_registry_task_id = azurerm_container_registry_task.frontendtask.id
  depends_on                 = [azurerm_container_registry_task_schedule_run_now.backendbuild]
}


# Create CosmosDB Account
resource "azurerm_cosmosdb_account" "acc" {
  name                      = var.cosmos_db_account_name
  location                  = var.resource_group_location
  resource_group_name       = var.resource_group_name
  offer_type                = "Standard"
  kind                      = "MongoDB"
  enable_automatic_failover = false
  enable_free_tier          = true
  capabilities {
    name = "EnableMongo"
  }
  consistency_policy {
    consistency_level       = "BoundedStaleness"
    max_interval_in_seconds = 400
    max_staleness_prefix    = 200000
  }
  geo_location {
    location          = var.resource_group_location
    failover_priority = 0
  }
}


# Create MongoDB database
resource "azurerm_cosmosdb_mongo_database" "mongodb" {
  name                = var.cosmos_db_database_name
  resource_group_name = azurerm_cosmosdb_account.acc.resource_group_name
  account_name        = azurerm_cosmosdb_account.acc.name
  throughput          = 400
  depends_on          = [azurerm_cosmosdb_account.acc]
}


# Create MongoDB collection
resource "azurerm_cosmosdb_mongo_collection" "coll" {
  name                = var.cosmos_db_collection_name
  resource_group_name = azurerm_cosmosdb_account.acc.resource_group_name
  account_name        = azurerm_cosmosdb_account.acc.name
  database_name       = azurerm_cosmosdb_mongo_database.mongodb.name
  default_ttl_seconds = "777"
  throughput          = 400
  index {
    keys   = ["_id"]
    unique = true
  }
  depends_on = [azurerm_cosmosdb_mongo_database.mongodb]
}


# random generation of aks cluster name
resource "random_pet" "prefix" {}


# After completeion run the following command to connect kubectl to cluster
# az aks get-credentials --resource-group $(terraform output -raw resource_group_name) --name $(terraform output -raw kubernetes_cluster_name)
# Azure Kubernetes cluster
resource "azurerm_kubernetes_cluster" "cluster" {
  name                = "${random_pet.prefix.id}-aks"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  dns_prefix          = "${random_pet.prefix.id}-k8s"

  default_node_pool {
    name       = "default"
    node_count = 1
    vm_size    = "Standard_D2_v2"
  }

  service_principal {
    client_id     = var.appId
    client_secret = var.password
  }

  network_profile {
    network_plugin    = "azure"
    load_balancer_sku = "standard"

  }

  role_based_access_control_enabled = true
}


# Kubernetes provider credentials
provider "kubernetes" {
  host                   = azurerm_kubernetes_cluster.cluster.kube_config.0.host
  client_certificate     = base64decode(azurerm_kubernetes_cluster.cluster.kube_config.0.client_certificate)
  client_key             = base64decode(azurerm_kubernetes_cluster.cluster.kube_config.0.client_key)
  cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.cluster.kube_config.0.cluster_ca_certificate)
}


# Kubernetes Deployment
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
  depends_on = [azurerm_kubernetes_cluster.cluster]
}


# Kubernetes Service
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
  depends_on = [kubernetes_deployment.api]
}


# Image name needs to be dynamic
# Azure Container Instance
resource "azurerm_container_group" "frontend" {
  name                = var.aci_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  ip_address_type     = "Private"
  network_profile_id  = azurerm_network_profile.frontendprofile.id
  os_type             = "Linux"

  # REQUIRED to access ACR image
  image_registry_credential {
    server   = "testcontainer12359.azurecr.io"
    username = azurerm_container_registry.acr.admin_username
    password = azurerm_container_registry.acr.admin_password
  }

  container {
    name   = "frontend-app"
    image  = "testcontainer12359.azurecr.io/frontend:ca2" # THIS NEEDS TO BE DYNAMIC!!!!!!<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< FIX THIS
    cpu    = "0.5"
    memory = "1.5"

    ports {
      port     = 80
      protocol = "TCP"
    }

    liveness_probe {
      initial_delay_seconds = 240
      period_seconds        = 60
      failure_threshold     = 2

      http_get {
        path   = "/"
        port   = 80
        scheme = "Http"
      }
    }

    # insert ENV variables into container for use by Python application
    environment_variables = ({
      COSMOS_ACC_NAME  = azurerm_cosmosdb_account.acc.name,
      COSMOS_DB_NAME   = var.cosmos_db_database_name
      COSMOS_COLL_NAME = var.cosmos_db_collection_name
      API_IP           = kubernetes_service.api.status.0.load_balancer.0.ingress.0.ip
    })
    secure_environment_variables = ({
      COSMOS_PRIMARY_KEY = azurerm_cosmosdb_account.acc.primary_key
    })
  }
  depends_on = [azurerm_container_registry_task_schedule_run_now.frontendbuild, azurerm_cosmosdb_account.acc, azurerm_network_profile.frontendprofile, kubernetes_service.api]
}
