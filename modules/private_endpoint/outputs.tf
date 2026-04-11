output "virtual_network_link_name" {
  value = azurerm_private_dns_zone_virtual_network_link.private_dns_zone_link.name
}

output "private_dns_zone_id" {
    value = azurerm_private_dns_zone.private_dns_zone.id
}