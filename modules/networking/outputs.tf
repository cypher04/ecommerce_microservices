output "vnet_id" {
    description = "The ID of the virtual network."
    value       = azurerm_virtual_network.vnet.id
}

output "subnet_ids" {
    description = "The IDs of the subnets."
    value       = {
        app      = azurerm_subnet.app_subnet.id
        database = azurerm_subnet.database_subnet.id
        aks      = azurerm_subnet.aks_subnet.id
        web      = azurerm_subnet.web_subnet.id
    }
}

