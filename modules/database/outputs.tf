output "flexible_server_id" {
    description = "The ID of the PostgreSQL Flexible Server."
    value       = azurerm_postgresql_flexible_server.ecommerce-db.id
}