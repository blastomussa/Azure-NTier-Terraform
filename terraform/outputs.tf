output "resource_group_name" {
  value = azurerm_resource_group.rg.name
}

output "kubernetes_cluster_name" {
  value = azurerm_kubernetes_cluster.k8s.name
}

output "gateway-ip" {
  value = azurerm_public_ip.gateway-pip.ip_address
}
