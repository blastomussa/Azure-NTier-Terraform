# Azure Container Instance
resource "azurerm_container_group" "frontend1" {
  name                = "frontend-app1"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  ip_address_type     = "Private"
  network_profile_id  = azurerm_network_profile.frontend1profile.id
  os_type             = "Linux"

  # REQUIRED to access ACR image
  image_registry_credential {
    server   = "${var.container_registry_name}.azurecr.io"
    username = azurerm_container_registry.acr.admin_username
    password = azurerm_container_registry.acr.admin_password
  }

  container {
    name   = "frontend-app"
    image  = "${var.container_registry_name}.azurecr.io/frontend:ca2"
    cpu    = "0.5"
    memory = "1.5"

    ports {
      port     = 80
      protocol = "TCP"
    }

    liveness_probe {
      initial_delay_seconds = 240
      period_seconds        = 60
      failure_threshold     = 2

      http_get {
        path   = "/"
        port   = 80
        scheme = "Http"
      }
    }

    # insert ENV variables into container for use by Python application
    environment_variables = ({
      COSMOS_ACC_NAME  = azurerm_cosmosdb_account.acc.name,
      COSMOS_DB_NAME   = var.cosmos_db_database_name
      COSMOS_COLL_NAME = var.cosmos_db_collection_name
      API_IP           = kubernetes_service.api.status.0.load_balancer.0.ingress.0.ip
      WHICH_APP        = "frontend-app1"
    })
    secure_environment_variables = ({
      COSMOS_PRIMARY_KEY = azurerm_cosmosdb_account.acc.primary_key
    })
  }
  depends_on = [azurerm_container_registry_task_schedule_run_now.frontendbuild, azurerm_cosmosdb_account.acc, azurerm_network_profile.frontend1profile, kubernetes_service.api]
}

resource "azurerm_container_group" "frontend2" {
  name                = "frontend-app2"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  ip_address_type     = "Private"
  network_profile_id  = azurerm_network_profile.frontend2profile.id
  os_type             = "Linux"

  # REQUIRED to access ACR image
  image_registry_credential {
    server   = "${var.container_registry_name}.azurecr.io"
    username = azurerm_container_registry.acr.admin_username
    password = azurerm_container_registry.acr.admin_password
  }

  container {
    name   = "frontend-app"
    image  = "${var.container_registry_name}.azurecr.io/frontend:ca2"
    cpu    = "0.5"
    memory = "1.5"

    ports {
      port     = 80
      protocol = "TCP"
    }

    liveness_probe {
      initial_delay_seconds = 240
      period_seconds        = 60
      failure_threshold     = 2

      http_get {
        path   = "/"
        port   = 80
        scheme = "Http"
      }
    }

    # insert ENV variables into container for use by Python application
    environment_variables = ({
      COSMOS_ACC_NAME  = azurerm_cosmosdb_account.acc.name,
      COSMOS_DB_NAME   = var.cosmos_db_database_name
      COSMOS_COLL_NAME = var.cosmos_db_collection_name
      API_IP           = kubernetes_service.api.status.0.load_balancer.0.ingress.0.ip
      WHICH_APP        = "frontend-app2"
    })
    secure_environment_variables = ({
      COSMOS_PRIMARY_KEY = azurerm_cosmosdb_account.acc.primary_key
    })
  }
  depends_on = [azurerm_container_registry_task_schedule_run_now.frontendbuild, azurerm_cosmosdb_account.acc, azurerm_network_profile.frontend2profile, kubernetes_service.api]
}
