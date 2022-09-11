variable "appId" {
  description = "Azure Kubernetes Service Cluster service principal"
}

variable "password" {
  description = "Azure Kubernetes Service Cluster password"
}

variable "resource_group_name" {
  default = "k8s-RG"
}

variable "resource_group_location" {
  default = "eastus"
}

variable "subscription_id" {
  description = "Subscription ID of Azure Tenant"
}

variable "github_pat" {
  description = "Github PAT scoped for access to public repos and repo status"
}

variable "container_registry_name" {
  default = "testcontainer12359"
}

variable "vnet_name" {
  default = "test-vnet"
}
