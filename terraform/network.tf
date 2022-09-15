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
  name                 = "gateway-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
  depends_on           = [azurerm_virtual_network.vnet]
}


# Subnet for Azure Container Instance
resource "azurerm_subnet" "frontend" {
  name                 = "frontend-subnet"
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
resource "azurerm_network_profile" "frontend1profile" {
  name                = "frontend1profile"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  container_network_interface {
    name = "frontend1nic"

    ip_configuration {
      name      = "frontend1ipconfig"
      subnet_id = azurerm_subnet.frontend.id
    }
  }
  depends_on = [azurerm_subnet.frontend]
}

resource "azurerm_network_profile" "frontend2profile" {
  name                = "frontend2profile"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  container_network_interface {
    name = "frontend2nic"

    ip_configuration {
      name      = "frontend2ipconfig"
      subnet_id = azurerm_subnet.frontend.id
    }
  }
  depends_on = [azurerm_subnet.frontend]
}


resource "azurerm_network_security_group" "frontendnsg" {
  name                = "frontend-nsg"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "AllowAppGatewayInbound"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "GatewayManager"
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "DenyInternetInbound"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "Internet"
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "frontendnsg" {
  subnet_id                 = azurerm_subnet.frontend.id
  network_security_group_id = azurerm_network_security_group.frontendnsg.id
}
