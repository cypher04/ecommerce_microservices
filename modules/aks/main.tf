resource "azurerm_kubernetes_cluster" "aks" {
    name                = "ecommerce-aks-cluster"
    location            = var.location
    resource_group_name = var.resource_group_name
    dns_prefix          = "ecommerceaks"
    sku_tier = "Free"
    oidc_issuer_enabled = true
    
    default_node_pool {
        name       = "default"
        node_count = 1
        vm_size    = "Standard_A2_v2"
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
        dns_service_ip = "10.0.0.10"
    }

   ingress_application_gateway {
        gateway_id = var.app_gateway_id
    }
   }


resource "azurerm_kubernetes_cluster_node_pool" "node_pool" {
    name                = "additional"
    kubernetes_cluster_id = azurerm_kubernetes_cluster.aks.id
    node_count         = 1
    vm_size            = "Standard_A2_v2"
    auto_scaling_enabled = true
    min_count          = 1
    max_count          = 3
}


resource "azurerm_role_assignment" "aks_acr_role" {
    scope                = var.acr_id
    role_definition_name = "AcrPull"
    principal_id         = azurerm_kubernetes_cluster.aks.identity.0.principal_id
}



resource "kubernetes_namespace_v1" "ecommerce_namespace" {
  metadata {
    name = "ecommerce-app"
  }
}

resource "kubernetes_secret_v1" "postgres_secret" {
  metadata {
    name      = "postgres-secret"
    namespace = kubernetes_namespace_v1.ecommerce_namespace.metadata[0].name
  }
    data = {
      username = var.admin_username
      password = var.admin_password
      DBHOSTNAME   = var.dbhostname
      DBNAME   = var.dbname
      DBPASSWORD = var.dbpassword
      DBUSERNAME = var.dbusername
      DBPORT = "5432"

    }

    type = "Opaque"
  
}


