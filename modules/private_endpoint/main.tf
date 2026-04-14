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

