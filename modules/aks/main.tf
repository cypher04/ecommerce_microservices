resource "azurerm_kubernetes_cluster" "aks" {
    name                = "ecommerce-aks-cluster"
    location            = var.location
    resource_group_name = var.resource_group_name
    dns_prefix          = "ecommerceaks"
    
    default_node_pool {
        name       = "default"
        node_count = 1
        vm_size    = "Standard_D2_v2"
    }
    
    identity {
        type = "SystemAssigned"
    }


        oms_agent {
            log_analytics_workspace_id = var.log_analytics_id
    }

    network_profile {
        network_plugin = "azure"
        service_cidr   = "10.0.0.0/16"
    }

   

}

resource "azurerm_kubernetes_cluster_node_pool" "node_pool" {
    name                = "additional"
    kubernetes_cluster_id = var.acr_id
    node_count         = 1
    vm_size            = "Standard_DS2_v2"
    auto_scaling_enabled = true
    min_count          = 1
    max_count          = 3
}


resource "azurerm_role_assignment" "aks_acr_role" {
    scope                = var.acr_id
    role_definition_name = "AcrPull"
    principal_id         = azurerm_kubernetes_cluster.aks.identity.0.principal_id
}

