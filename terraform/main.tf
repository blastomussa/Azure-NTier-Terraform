/*
The goal of this project is to deploy as many resources as possible with terraform

DONE(ish):
  Resource Group
  CosmosDB Account
    Database + Collection

TO DO:
  vNet
  Azure Container Instance (w/ mongo ENV variables)
  App Service
  Azure Container Registry?
  Application Gateway
  Any other networking components to route traffic correctly between tiers
    (Private Link, DNS Zone)

*/
terraform {
  required_version = ">= 0.12.6"
  required_providers {
    azurerm = {
      version = "~> 2.53.0"
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
