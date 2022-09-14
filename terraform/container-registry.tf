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
    context_path         = "https://github.com/blastomussa/Azure-NTier-Terraform.git#master"
    context_access_token = var.github_pat
    image_names          = ["backend:{{.Run.ID}}"]
  }
  source_trigger {
    name           = "github-trigger"
    events         = ["commit"]
    repository_url = "https://github.com/blastomussa/Azure-NTier-Terraform"
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


# Build Docker image for frontend API with ACR task
resource "azurerm_container_registry_task" "frontendtask" {
  name                  = "frontend-task"
  container_registry_id = azurerm_container_registry.acr.id
  platform {
    os = "Linux"
  }
  docker_step {
    dockerfile_path      = "frontend/Dockerfile" //this might need to be changed
    context_path         = "https://github.com/blastomussa/Azure-NTier-Terraform.git#master"
    context_access_token = var.github_pat
    image_names          = ["frontend:{{.Run.ID}}"]
  }
  source_trigger {
    name           = "github-trigger"
    events         = ["commit"]
    repository_url = "https://github.com/blastomussa/Azure-NTier-Terraform"
    source_type    = "Github"

    authentication {
      token      = var.github_pat
      token_type = "PAT"
    }
  }
  depends_on = [azurerm_container_registry.acr]
}


# Run the frontendtask manually
resource "azurerm_container_registry_task_schedule_run_now" "frontendbuild" {
  container_registry_task_id = azurerm_container_registry_task.frontendtask.id
  depends_on                 = [azurerm_container_registry_task_schedule_run_now.backendbuild]
}
