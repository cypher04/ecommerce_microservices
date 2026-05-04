resource "azurerm_virtual_network" "vnet" {
  name                = "${var.resource_group_name}-vnet"
  address_space       = var.address_space
  location            = var.location
  resource_group_name = var.resource_group_name
}

resource "azurerm_subnet" "app_subnet" {
  name                 = "${var.resource_group_name}-subnet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.subnet_prefixes["app"]]
}

resource "azurerm_subnet" "database_subnet" {
  name                 = "${var.resource_group_name}-db-subnet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.subnet_prefixes["database"]]
  service_endpoints = ["Microsoft.Storage"]
  delegation {
        name = "fs"
        service_delegation {
            name    = "Microsoft.DBforPostgreSQL/flexibleServers"
            actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
        }
         
  }
}

resource "azurerm_subnet" "aks_subnet" {
  name                 = "${var.resource_group_name}-aks-subnet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.subnet_prefixes["aks"]]
  
  #   delegation {
  #   name = "aciDelegation"
  #   service_delegation {
  #     name    = "Microsoft.ContainerInstance/containerGroups"
  #     actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
  #   }
  # }
}

resource "azurerm_subnet" "web_subnet" {
  name                 = "${var.resource_group_name}-web-subnet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.subnet_prefixes["web"]]
  
}

# resource "azurerm_subnet" "appgw" {
#     name                 = "${var.resource_group_name}-appgw-subnet"
#     resource_group_name  = var.resource_group_name
#     virtual_network_name = azurerm_virtual_network.vnet.name
#     address_prefixes     = [var.subnet_prefixes["appgw"]]
# }

resource "azurerm_public_ip" "app_gateway_public_ip" {
  name                = "${var.resource_group_name}-appgw-pip"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
}
