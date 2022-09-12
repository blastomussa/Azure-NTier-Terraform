variable "subscription_id" {
  description = "Subscription ID of Azure Tenant"
}

variable "github_pat" {
  description = "Github PAT scoped for access to public repos and repo status"
}

variable "appId" {
  description = "Azure Kubernetes Service Cluster service principal"
}

variable "password" {
  description = "Azure Kubernetes Service Cluster password"
}

variable "resource_group_name" {
  default = "AzProject-RG"
}

variable "resource_group_location" {
  default = "eastus"
}

variable "cosmos_db_account_name" {
  default = "tf-cosmos-jcourtney"
}

variable "cosmos_db_database_name" {
  default = "mongo-db"
}

variable "cosmos_db_collection_name" {
  default = "data_collection"
}

variable "container_registry_name" {
  default = "projregistry10293"
}

variable "vnet_name" {
  default = "azproject-vnet"
}

variable "aci_name" {
  default = "frontend-app"
}
