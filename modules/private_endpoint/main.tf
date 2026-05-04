resource "azurerm_private_dns_zone" "private_dns_zone" {
  name                = "privatelink.postgres.database.azure.com"
  resource_group_name = var.resource_group_name
  
}

resource "azurerm_private_dns_zone_virtual_network_link" "private_dns_zone_link" {
  name                  = "private-dns-zone-link"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.private_dns_zone.name
  virtual_network_id    = var.vnet_id
  
  depends_on = [ var.subnet_prefixes]
}

# resource "azurerm_private_endpoint" "ecommerce_private_endpoint" {
#   name                = "ecommerce-private-endpoint"
#   location            = var.location
#   resource_group_name = var.resource_group_name
#   subnet_id           = var.subnet_ids["database"]

#   private_service_connection {
#     name                           = "postgresql-flexible-server-connection"
#     is_manual_connection            = false
#     private_connection_resource_id   = var.flexible_server_id
#     subresource_names               = ["postgresqlServer"]
#   }
  
# }

// create private endpoint for container registry

resource "azurerm_private_endpoint" "container_registry" {
  name                = "${var.resource_group_name}-acr-pe"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.subnet_ids["app"]

  private_service_connection {
    name                           = "${var.resource_group_name}-acr-psc"
    private_connection_resource_id = var.acr_id
    subresource_names              = ["registry"]
    is_manual_connection           = false
  }


  private_dns_zone_group {
    name                 = "${var.resource_group_name}-acr-dnszonegroup"
    private_dns_zone_ids = [azurerm_private_dns_zone.acr_dns_zone.id]
  }

}

resource "azurerm_private_dns_zone" "acr_dns_zone" {
  name                = "privatelink.azurecr.io"
  resource_group_name = var.resource_group_name
  
}

resource "azurerm_private_dns_zone_virtual_network_link" "acr_dns_zone_link" {
  name                  = "${var.resource_group_name}-acr-dnszone-link"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.acr_dns_zone.name
  virtual_network_id    = var.vnet_id
  
  depends_on = [ var.subnet_prefixes]
}

