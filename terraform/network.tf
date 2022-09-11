# Create VNet and subnets
resource "azurerm_virtual_network" "vnet" {
  name                = var.vnet_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = ["10.0.0.0/16"]
  depends_on          = [azurerm_resource_group.rg]
}


# Subnet for Application Gateway
resource "azurerm_subnet" "gateway" {
  name                 = "gateway"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
  depends_on           = [azurerm_virtual_network.vnet]
}


# Subnet for Azure Container Instance 
resource "azurerm_subnet" "frontend" {
  name                 = "frontend"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.2.0/24"]

  delegation {
    name = "delegation"

    service_delegation { //Container Instance REQUIRES delegation
      name    = "Microsoft.ContainerInstance/containerGroups"
      actions = ["Microsoft.Network/virtualNetworks/subnets/action", "Microsoft.Network/virtualNetworks/subnets/join/action", "Microsoft.Network/virtualNetworks/subnets/prepareNetworkPolicies/action"]
    }
  }
  depends_on = [azurerm_virtual_network.vnet]
}


# Network Profile for private IP address of container instance
resource "azurerm_network_profile" "frontendprofile" {
  name                = "frontendprofile"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  container_network_interface {
    name = "frontendnic"

    ip_configuration {
      name      = "frontendipconfig"
      subnet_id = azurerm_subnet.frontend.id
    }
  }
  depends_on = [azurerm_subnet.frontend]
}
