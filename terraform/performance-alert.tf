resource "azurerm_monitor_action_group" "ag" {
  name                = "projectactiongroup"
  resource_group_name = azurerm_resource_group.rg.name
  short_name          = "azureproj"

  email_receiver {
    name                    = "sendtojoe"
    email_address           = "jccourtn@gmail.com"
    use_common_alert_schema = true
  }

}

resource "azurerm_monitor_metric_alert" "alert" {
  name                 = "project-metricalert"
  resource_group_name  = azurerm_resource_group.rg.name
  scopes               = [azurerm_container_group.frontend1.id]
  description          = "Alert for Azure Project"
  target_resource_type = "Microsoft.ContainerInstance/containerGroups"

  criteria {
    metric_namespace = "Microsoft.ContainerInstance/containerGroups"
    metric_name      = "CpuUsage"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 1
  }

  severity = 0

  frequency = "PT1M" #check every minute 

  action {
    action_group_id = azurerm_monitor_action_group.ag.id
  }
}