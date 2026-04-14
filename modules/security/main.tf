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




// Application Gateway and WAF policies

locals {
  backend_address_pool_name      = "${var.resource_group_name}-beap"
  frontend_port_name             = "${var.resource_group_name}-feport"
  frontend_ip_configuration_name = "${var.resource_group_name}-feip"
  http_setting_name              = "${var.resource_group_name}-be-htst"
  listener_name                  = "${var.resource_group_name}-httplstn"
  request_routing_rule_name      = "${var.resource_group_name}-rqrt"
  redirect_configuration_name    = "${var.resource_group_name}-rdrcfg"
}

resource "azurerm_application_gateway" "appgw" {
  name                = "${var.resource_group_name}-appgateway"
  resource_group_name = var.resource_group_name
  location            = var.location

waf_configuration {
    enabled = true
    firewall_mode = "Prevention"
    rule_set_type = "OWASP"
    rule_set_version = "3.2"
}

  sku {
    name     = "WAF_v2"
    tier     = "WAF_v2"
    capacity = 2
  }

  gateway_ip_configuration {
    name      = "my-gateway-ip-configuration"
    subnet_id = var.subnet_ids["appgw"]
  }

  frontend_port {
    name = local.frontend_port_name
    port = 80
  }

  frontend_ip_configuration {
    name                 = local.frontend_ip_configuration_name
    public_ip_address_id = var.app_gateway_public_ip_id
  }

  backend_address_pool {
    name = local.backend_address_pool_name
  }

  backend_http_settings {
    name                  = local.http_setting_name
    cookie_based_affinity = "Disabled"
    path                  = "/path1/"
    port                  = 80
    protocol              = "Http"
    request_timeout       = 60
  }

  http_listener {
    name                           = local.listener_name
    frontend_ip_configuration_name = local.frontend_ip_configuration_name
    frontend_port_name             = local.frontend_port_name
    protocol                       = "Http"
  }

  request_routing_rule {
    name                       = local.request_routing_rule_name
    priority                   = 9
    rule_type                  = "Basic"
    http_listener_name         = local.listener_name
    backend_address_pool_name  = local.backend_address_pool_name
    backend_http_settings_name = local.http_setting_name
  }


  lifecycle {
    ignore_changes = [ 
        backend_address_pool,
        backend_http_settings,
        request_routing_rule
     ]
  }
}






