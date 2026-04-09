resource "azurerm_network_security_group" "aks_nsg" {
  name                = "${var.resource_group_name}-nsg"
  location            = var.location
  resource_group_name = var.resource_group_name
}

resource "azurerm_network_security_group" "web_nsg" {
  name                = "${var.resource_group_name}-web-nsg"
  location            = var.location
  resource_group_name = var.resource_group_name
}

resource "azurerm_network_security_group" "database_nsg" {
  name                = "${var.resource_group_name}-db-nsg"
  location            = var.location
  resource_group_name = var.resource_group_name
  
}




