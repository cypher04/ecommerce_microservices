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
        # agc      = azurerm_subnet.agc_subnet.id
    }
}

output "public_ip_id" {
    description = "The ID of the public IP address for the Application Gateway."
    value       = azurerm_public_ip.app_gateway_public_ip.id
}

# output "alb_id" {
#     description = "The ID of the load balancer for the AGC."
#     value       = azurerm_application_load_balancer.alb.id
# }

// output alb identity 
# output "alb_identity_id" {
#     description = "The ID of the managed identity for the load balancer."
#     value       = azurerm_user_assigned_identity.alb_identity.id
# }






