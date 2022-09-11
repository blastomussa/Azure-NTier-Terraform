# After completeion run the following command to connect kubectl to cluster
#az aks get-credentials --resource-group $(terraform output -raw resource_group_name) --name $(terraform output -raw kubernetes_cluster_name)
terraform {
  required_version = ">= 1.2"
  required_providers {
    azurerm = {
      version = "~> 3.22.0"
    }
  }
}

resource "random_pet" "prefix" {}

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
    context_path         = "https://github.com/blastomussa/AzureProjectF22.git#master"
    context_access_token = var.github_pat
    image_names          = ["backend:{{.Run.ID}}"]
  }
  source_trigger {
    name           = "github-trigger"
    events         = ["commit"]
    repository_url = "https://github.com/blastomussa/AzureProjectF22"
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


resource "azurerm_kubernetes_cluster" "cluster" {
  name                = "${random_pet.prefix.id}-aks"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  dns_prefix          = "${random_pet.prefix.id}-k8s"

  default_node_pool {
    name            = "default"
    node_count      = 2
    vm_size         = "Standard_D2_v2"
    os_disk_size_gb = 30
  }

  service_principal {
    client_id     = var.appId
    client_secret = var.password
  }


  role_based_access_control_enabled = true
}
