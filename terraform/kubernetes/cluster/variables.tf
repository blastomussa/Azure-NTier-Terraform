variable "appId" {
  description = "Azure Kubernetes Service Cluster service principal"
}

variable "password" {
  description = "Azure Kubernetes Service Cluster password"
}

variable "subscription_id" {
  default = "397b1839-a1f6-41ec-8b40-b97cf5258c0f"
}

variable "resource_group_name" {
  default = "k8s-RG"
}

variable "resource_group_location" {
  default = "eastus"
}
