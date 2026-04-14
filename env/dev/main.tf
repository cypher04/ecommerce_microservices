resource "azurerm_resource_group" "ecommerce_rg" {
  name     = "${var.project_name}${var.environment}-rg"
  location = var.location


  tags = {
    project     = var.project_name
    environment = var.environment
  }
  
}


module "compute" {
  source              = "../../modules/compute"
  location            = var.location
  resource_group_name      = azurerm_resource_group.ecommerce_rg.name
  acr_name = var.acr_name

}

module "aks" {
  source              = "../../modules/aks"
  location            = var.location
  resource_group_name      = azurerm_resource_group.ecommerce_rg.name
  log_analytics_id = module.monitoring.log_analytics_id
  acr_id = module.compute.acr_id
  app_gateway_id = module.security.app_gateway_id


  depends_on = [module.networking]
}


module "networking" {
  source              = "../../modules/networking"
  location            = var.location
  subnet_prefixes     = var.subnet_prefixes
  address_space       = var.address_space
  resource_group_name = azurerm_resource_group.ecommerce_rg.name
  acr_name = var.acr_name
}


module "security" {
  source              = "../../modules/security"
  location            = var.location
  resource_group_name = azurerm_resource_group.ecommerce_rg.name
  subnet_prefixes = var.subnet_prefixes
  subnet_ids = module.networking.subnet_ids
  app_gateway_public_ip_id = module.networking.app_gateway_public_ip_id
  
}

module "monitoring" {
    source              = "../../modules/monitoring"
    location            = var.location
    resource_group_name = azurerm_resource_group.ecommerce_rg.name
}


module "database" {
    source              = "../../modules/database"
    location            = var.location
    resource_group_name = azurerm_resource_group.ecommerce_rg.name
    private_dns_zone_id = module.private_endpoint.private_dns_zone_id
    admin_username = var.admin_username
    admin_password = var.admin_password
    virtual_network_link_name = module.private_endpoint.virtual_network_link_name
    subnet_prefixes = var.subnet_prefixes
    subnet_ids = module.networking.subnet_ids
}

module "private_endpoint" {
    source              = "../../modules/private_endpoint"
    location            = var.location
    resource_group_name = azurerm_resource_group.ecommerce_rg.name
   vnet_id = module.networking.vnet_id
   subnet_prefixes = var.subnet_prefixes
   flexible_server_id = module.database.flexible_server_id
   subnet_ids = module.networking.subnet_ids
}