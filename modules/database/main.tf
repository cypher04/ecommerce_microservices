resource "azurerm_postgresql_flexible_server" "ecommerce-db" {
  name                = var.dbname
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
  
  depends_on = [ var.virtual_network_link_name ]
}