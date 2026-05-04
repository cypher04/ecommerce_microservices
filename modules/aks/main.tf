resource "azurerm_kubernetes_cluster" "aks" {
    name                = "ecommerce-aks-cluster"
    location            = var.location
    resource_group_name = var.resource_group_name
    dns_prefix          = "ecommerceaks"
    sku_tier = "Free"
    oidc_issuer_enabled = true
    workload_identity_enabled = true
    
    default_node_pool {
        name       = "default"
        node_count = 1
        vm_size    = "Standard_A2_v2"
        vnet_subnet_id = var.subnet_ids["aks"]
    }
    
    identity {
        type = "SystemAssigned"
    }


        oms_agent {
            log_analytics_workspace_id = var.log_analytics_id
    }

    network_profile {
        network_plugin = "azure"
        service_cidr   = "10.2.0.0/16"
        dns_service_ip = "10.2.0.10"
    }
    

   }


   resource "null_resource" "aks_get_credentials" {
  triggers = {
    cluster_id = azurerm_kubernetes_cluster.aks.id
  }

  provisioner "local-exec" {
    command = "az aks get-credentials --resource-group ${var.resource_group_name} --name ${azurerm_kubernetes_cluster.aks.name} --overwrite-existing"
  }
}


resource "azurerm_kubernetes_cluster_node_pool" "node_pool" {
    name                = "additional"
    kubernetes_cluster_id = azurerm_kubernetes_cluster.aks.id
    node_count         = 1
    vm_size            = "Standard_A2_v2"
    vnet_subnet_id = var.subnet_ids["aks"]
    auto_scaling_enabled = true
    min_count          = 1
    max_count          = 3
}


resource "azurerm_role_assignment" "aks_acr_role" {
    scope                = var.acr_id
    role_definition_name = "AcrPull"
    principal_id         = azurerm_kubernetes_cluster.aks.kubelet_identity[0].object_id
}



resource "kubernetes_namespace_v1" "ecommerce_namespace" {
  metadata {
    name = "ecommerce-app"
  }
}

resource "kubernetes_secret_v1" "postgres_secret" {
  metadata {
    name      = "basic-auth"
    namespace = kubernetes_namespace_v1.ecommerce_namespace.metadata[0].name
  }
    data = {
      admin_username = var.admin_username
      admin_password = var.admin_password
      DB_HOST   = var.db_host
      DB_NAME   = var.db_name
      DB_PASSWORD = var.db_password
      DB_USER = var.db_user
      DB_PORT = "5432"

    }

    type = "Opaque"
  
}


// federated identity for ALB to access the load balancer and AGC configuration manager

# # resource "azurerm_federated_identity_credential" "alb_federated_identity" {
# #   name                = "${var.resource_group_name}-alb-federated-identity"
# #   issuer              = var.oidc_issuer_url
# #   subject             = "system:serviceaccount:azure-alb-system:alb-controller-sa"
# #   audience           = ["api://AzureADTokenExchange"]
# #   user_assigned_identity_id = var.alb_identity_id
# }