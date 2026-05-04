resource "azurerm_postgresql_flexible_server" "ecommerce-db-2" {
  name                = "ecommerce-db-2"
  resource_group_name = var.resource_group_name
  location            = var.location
  delegated_subnet_id = var.subnet_ids["database"]
  private_dns_zone_id = var.private_dns_zone_id
  public_network_access_enabled = false
  administrator_login = var.admin_username
  administrator_password = var.admin_password
  zone = "2"
  version             = "12"
  storage_mb          = 32768
  storage_tier = "P4"
  sku_name = "B_Standard_B1ms"
}




resource "azurerm_postgresql_flexible_server_database" "ecommerce_db" {
  name                = "ecommerce-database"
  charset             = "UTF8"
  collation           = "en_US.utf8"
  server_id = azurerm_postgresql_flexible_server.ecommerce-db-2.id

}
