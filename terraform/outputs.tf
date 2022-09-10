output "gateway-ip" {
  value = azurerm_public_ip.gateway-pip.ip_address
}
