/*
The goal of this project is to deploy as many resources as possible with terraform

DONE(ish):
  Resource Group
  CosmosDB Account
    Database + Collection
  Azure Container Registry
    Task to rebuild new backend docker image with every commit to master branch
    Run task to create initial Docker images for the backend and frontend
  Vnet and subnets

TO DO:
  NSG
  Azure Container Instance (w/ mongo ENV variables)
  App Service
  Application Gateway
  Any other networking components to route traffic correctly between tiers
    (Private Link, DNS Zone, public ip?)

*/
# azurerm version 3.22 is required for newer resource types (task)
terraform {
  required_version = ">= 1.2"
  required_providers {
    azurerm = {
      version = "~> 3.22.0"
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


# Create Network Security Group


# Create VNet and subnets
resource "azurerm_virtual_network" "vnet" {
  name                = var.vnet_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = ["10.0.0.0/16"]
  subnet {
    name           = "gateway"
    address_prefix = "10.0.1.0/24"
  }
  subnet {
    name           = "frontend"
    address_prefix = "10.0.2.0/24"
  }
  subnet {
    name           = "backend"
    address_prefix = "10.0.3.0/24"
  }
  depends_on = [azurerm_resource_group.rg]
}


# Create Azure Container Registry
resource "azurerm_container_registry" "acr" {
  name                = var.container_registry_name
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "Basic"
  admin_enabled       = false
  depends_on          = [azurerm_resource_group.rg]
}


# Build Docker image for backend API with ACR task
# THIS NEEDS TO BE TESTED
resource "azurerm_container_registry_task" "backendtask" {
  name                  = "backend-task"
  container_registry_id = azurerm_container_registry.acr.id
  platform {
    os = "Linux"
  }
  docker_step {
    dockerfile_path      = "/backend/Dockerfile" //this might need to be changed
    context_path         = "https://github.com/blastomussa/AzureProjectF22.git#master"
    context_access_token = var.github_pat
    image_names          = ["backend:latest"]
  }
  depends_on = [azurerm_container_registry.acr]
}


# Run the previously created task
# THIS NEEDS TO BE TESTED
resource "azurerm_container_registry_task_schedule_run_now" "backendbuild" {
  container_registry_task_id = azurerm_container_registry_task.backendtask.id
}


# Build Docker image for frontend API with ACR task
# THIS NEEDS TO BE TESTED
resource "azurerm_container_registry_task" "frontendtask" {
  name                  = "frontend-task"
  container_registry_id = azurerm_container_registry.acr.id
  platform {
    os = "Linux"
  }
  docker_step {
    dockerfile_path      = "/frontend/Dockerfile" //this might need to be changed
    context_path         = "https://github.com/blastomussa/AzureProjectF22.git#master"
    context_access_token = var.github_pat
    image_names          = ["frontend:latest"]
  }
  depends_on = [azurerm_container_registry.acr]
}


# Run the previously created task
# THIS NEEDS TO BE TESTED
resource "azurerm_container_registry_task_schedule_run_now" "frontendbuild" {
  container_registry_task_id = azurerm_container_registry_task.frontendtask.id
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
  shard_key           = "uniqueKey"
  throughput          = 400
  lifecycle {
    ignore_changes = [index]
  }
  depends_on = [azurerm_cosmosdb_mongo_database.mongodb]
}


# Container Instance frontend

# Application Gateway

# App Service backend API
