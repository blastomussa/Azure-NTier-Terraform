# random generation of aks cluster name
resource "random_pet" "prefix" {}

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

# After completion run the following command to connect local kubectl to cluster
# az aks get-credentials --resource-group $(terraform output -raw resource_group_name) --name $(terraform output -raw kubernetes_cluster_name)
