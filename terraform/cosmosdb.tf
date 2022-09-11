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
