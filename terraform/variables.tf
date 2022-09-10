variable "subscription_id" {
  description = "Subscription ID of Azure Tenant"
}

variable "github_pat" {
  description = "Github PAT scoped for access to public repos and repo status"
}

variable "resource_group_name" {
  default = "tfCosmos-RG"
}

variable "resource_group_location" {
  default = "eastus"
}

variable "cosmos_db_account_name" {
  default = "tf-cosmos-jcourtney"
}

variable "cosmos_db_database_name" {
  default = "test-db"
}

variable "cosmos_db_collection_name" {
  default = "test_collection"
}

variable "container_registry_name" {
  default = "testcontainer12359"
}

variable "vnet_name" {
  default = "test-vnet"
}

variable "aci_name" {
  default = "frontend-app"
}