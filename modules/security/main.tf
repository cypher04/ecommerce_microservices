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

resource "azurerm_network_security_group" "appgw_nsg" {
  name                = "${var.resource_group_name}-appgw-nsg"
  location            = var.location
  resource_group_name = var.resource_group_name
  
}


// NSG Associations

resource "azurerm_subnet_network_security_group_association" "aks_nsg_assoc" {
  subnet_id                 = var.subnet_ids["aks"]
  network_security_group_id = azurerm_network_security_group.aks_nsg.id
}

resource "azurerm_subnet_network_security_group_association" "appgw_nsg_assoc" {
  subnet_id                 = var.subnet_ids["appgw"]
  network_security_group_id = azurerm_network_security_group.appgw_nsg.id
}

resource "azurerm_subnet_network_security_group_association" "web_nsg_assoc" {
  subnet_id                 = var.subnet_ids["web"]
  network_security_group_id = azurerm_network_security_group.web_nsg.id
}

resource "azurerm_subnet_network_security_group_association" "database_nsg_assoc" {
  subnet_id                 = var.subnet_ids["database"]
  network_security_group_id = azurerm_network_security_group.database_nsg.id
}


// NSG Rules



resource "azurerm_network_security_rule" "allow_aks_to_db" {
  name                        = "Allow_AKS_to_DB"
  resource_group_name = var.resource_group_name
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "5432"
  source_address_prefixes      = [var.subnet_prefixes["aks"]]
  destination_address_prefixes = [var.subnet_prefixes["database"]]
  network_security_group_name = azurerm_network_security_group.database_nsg.name
  
}

resource "azurerm_network_security_rule" "allow_web_to_aks" {
  name                        = "Allow_Web_to_AKS"
  resource_group_name = var.resource_group_name
  priority                    = 110
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "65200-65535"
  destination_port_range      = "80-443"
  source_address_prefixes      = [var.subnet_prefixes["appgw"]]
  destination_address_prefixes = [var.subnet_prefixes["aks"]]
  network_security_group_name = azurerm_network_security_group.appgw_nsg.name
  
}


resource "azurerm_network_security_rule" "allow_appgw_health_probes" {
  name                        = "Allow_AppGW_Health_Probes"
  resource_group_name         = var.resource_group_name
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "65200-65535"
  source_address_prefix       = "GatewayManager"
  destination_address_prefix  = "*"
  network_security_group_name = azurerm_network_security_group.appgw_nsg.name
}

resource "azurerm_network_security_rule" "deny_web_to_db" {
  name                        = "Deny_Web_to_DB"
  resource_group_name = var.resource_group_name
  priority                    = 120
  direction                   = "Inbound"
  access                      = "Deny"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "5432"
  source_address_prefixes      = [var.subnet_prefixes["appgw"]]
  destination_address_prefixes = [var.subnet_prefixes["database"]]
  network_security_group_name = azurerm_network_security_group.database_nsg.name
  
}

resource "azurerm_network_security_rule" "allow_database_to_aks" {
  name                        = "Allow_DB_to_AKS"
  resource_group_name = var.resource_group_name
  priority                    = 130
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "80-443"
  source_address_prefixes      = [var.subnet_prefixes["database"]]
  destination_address_prefixes = [var.subnet_prefixes["aks"]]
  network_security_group_name = azurerm_network_security_group.aks_nsg.name
  
}




