resource "azurerm_resource_group" "ecommerce_rg" {
  name     = var.resource_group_name
  location = var.location


  tags = {
    project     = var.project_name
    environment = var.environment
  }
  
}

data "azurerm_client_config" "current" {
}


resource "helm_release" "helm_auth" {
  name       = "ecommerce-helm-auth-4"
  namespace  = "ecommerce-app"
  chart      = "../../helm/apps-auth-service/"
  # version    = "0.1.0"
  timeout = 6000
}

resource "helm_release" "helm_order" {
  name       = "ecommerce-helm-order"
  namespace  = "ecommerce-app"
  chart      = "../../helm/apps-order-service/"
        # version    = "0.1.0"
  timeout = 6000
}

# resource "helm_release" "helm_frontend" {
#   name       = "ecommerce-helm"
#   namespace  = "ecommerce-app"
#   chart      = "../../helm/apps-frontend/"
#   version    = "0.1.0"
# }

# resource "helm_release" "helm_payment" {
#   name       = "ecommerce-helm"
#   namespace  = "ecommerce-app"
#   chart      = "../../helm/apps-payment-service/"
#   version    = "0.1.0"
# }

resource "helm_release" "helm-product" {
  name       = "ecommerce-helm-product-7"
  namespace  = "ecommerce-app"
  chart      = "../../helm/apps-product-service/"
  # version    = "0.2.0"
  timeout = 6000
}

# resource "helm_release" "agc_helm" {
#   name       = "ecommerce-agc-helm"
#   namespace  = "ecommerce-app"
#   chart      ="oci://mcr.microsoft.com/application-lb/charts/alb-controller"
#    version    = "1.5.0"
#   # version    = "0.1.0"
#   timeout = 6000
    

#   depends_on = [module.aks]

  
# }

# resource "helm_release" "helm_product-2" {
#   name       = "ecommerce-helm-2"
#   namespace  = "ecommerce-app"
#   chart      = "../../helm/apps-product-service/"
#   # version    = "0.1.0"
#   timeout = 6000
#   wait = false
# }


module "compute" {
  source              = "../../modules/compute"
  location            = var.location
  resource_group_name      = azurerm_resource_group.ecommerce_rg.name
  acr_name = var.acr_name
  vm_admin_name = var.vm_admin_name
  vm_admin_password = var.vm_admin_password
  subnet_ids = module.networking.subnet_ids

}

module "aks" {
  source              = "../../modules/aks"
  location            = var.location
  resource_group_name      = azurerm_resource_group.ecommerce_rg.name
  log_analytics_id = module.monitoring.log_analytics_id
  acr_id = module.compute.acr_id
  # app_gateway_id = module.security.app_gateway_id
  admin_username = var.admin_username
  admin_password = var.admin_password
  db_host = var.db_host
  db_name = var.db_name
  db_user = var.db_user
  db_password = var.db_password
  # alb_identity_id = module.networking.alb_identity_id
  oidc_issuer_url = module.aks.oidc_issuer_url
  subnet_ids = module.networking.subnet_ids
  vnet_id = module.networking.vnet_id

  # depends_on = [module.networking]
}


module "networking" {
  source              = "../../modules/networking"
  location            = var.location
  subnet_prefixes     = var.subnet_prefixes
  address_space       = var.address_space
  resource_group_name = azurerm_resource_group.ecommerce_rg.name
  acr_name = var.acr_name
  oidc_issuer_url = module.aks.oidc_issuer_url


  # depends_on = [ module.aks ]
}


module "security" {
  source              = "../../modules/security"
  location            = var.location
  resource_group_name = azurerm_resource_group.ecommerce_rg.name
  subnet_prefixes = var.subnet_prefixes
  subnet_ids = module.networking.subnet_ids
  acr_id = module.compute.acr_id
  vnet_id = module.networking.vnet_id
}

module "monitoring" {
    source              = "../../modules/monitoring"
    location            = var.location
    resource_group_name = azurerm_resource_group.ecommerce_rg.name
}


module "database" {
  source              = "../../modules/database"
  location            = var.location
  resource_group_name = azurerm_resource_group.ecommerce_rg.name
  private_dns_zone_id = module.private_endpoint.private_dns_zone_id
  admin_username      = var.admin_username
  admin_password      = var.admin_password
  subnet_prefixes     = var.subnet_prefixes
  subnet_ids          = module.networking.subnet_ids
  dbname              = var.db_name

  depends_on = [module.private_endpoint]
}

module "private_endpoint" {
  source              = "../../modules/private_endpoint"
  location            = var.location
  resource_group_name = azurerm_resource_group.ecommerce_rg.name
  vnet_id             = module.networking.vnet_id
  subnet_prefixes     = var.subnet_prefixes
  subnet_ids          = module.networking.subnet_ids
  acr_id              = module.compute.acr_id
}