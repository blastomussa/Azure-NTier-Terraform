# random generation of aks cluster name
resource "random_pet" "prefix" {}

# for log analytics unique name
resource "random_id" "log_analytics_workspace_name_suffix" {
  byte_length = 8
}

# log analytics
resource "azurerm_log_analytics_workspace" "log" {
  location            = var.resource_group_location
  # The WorkSpace name has to be unique across the whole of azure;
  # not just the current subscription/tenant.
  name                = "${var.log_analytics_workspace_name}-${random_id.log_analytics_workspace_name_suffix.dec}"
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = var.log_analytics_workspace_sku
}

resource "azurerm_log_analytics_solution" "logsolution" {
  location              = azurerm_log_analytics_workspace.log .location
  resource_group_name   = azurerm_resource_group.rg.name
  solution_name         = "ContainerInsights"
  workspace_name        = azurerm_log_analytics_workspace.log.name
  workspace_resource_id = azurerm_log_analytics_workspace.log.id

  plan {
    product   = "OMSGallery/ContainerInsights"
    publisher = "Microsoft"
  }
}

# Azure Kubernetes cluster
resource "azurerm_kubernetes_cluster" "k8s" {
  name                = "${random_pet.prefix.id}-aks"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  dns_prefix          = "${random_pet.prefix.id}-k8s"

  default_node_pool {
    name       = "default"
    node_count = var.node_count
    vm_size    = "Standard_D2_v2"
  }

  linux_profile {
    admin_username = "ubuntu"

    ssh_key {
      key_data = file(var.ssh_public_key)
    }
  }

  service_principal {
    client_id     = var.appId
    client_secret = var.password
  }

  network_profile {
    network_plugin    = "kubenet"
    load_balancer_sku = "standard"

  }

  role_based_access_control_enabled = true
}

# After completion run the following command to connect local kubectl to cluster
# az aks get-credentials --resource-group $(terraform output -raw resource_group_name) --name $(terraform output -raw kubernetes_cluster_name)
