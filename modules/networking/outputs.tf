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
        appgw    = azurerm_subnet.appgw.id
    }
}

output "app_gateway_public_ip_id" {
    description = "The ID of the public IP address for the Application Gateway."
    value       = azurerm_public_ip.app_gateway_public_ip.id
}