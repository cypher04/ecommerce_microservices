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


resource "azurerm_user_assigned_identity" "alb_user_id" {
  name                = "${var.project_name}-alb-identity"
  resource_group_name = azurerm_resource_group.ecommerce_rg.name
  location            = var.location
}


resource "azurerm_federated_identity_credential" "alb_federated_identity" {
  name                = "${var.project_name}-alb-federated-identity"
  audience = ["api://AzureADTokenExchange"]
  user_assigned_identity_id = azurerm_user_assigned_identity.alb_user_id.id
  issuer              = module.aks.oidc_issuer_url
  subject             = "system:serviceaccount:ecommerce-app:alb-service-account"
}



resource "helm_release" "helm_auth" {
  name       = "ecommerce-helm-auth-4"
  namespace  = "ecommerce-app"
  chart      = "../../helm/apps-auth-service/"
  # version    = "0.1.0"
  timeout = 6000

  depends_on = [ helm_release.shared_gateway ]

}

resource "helm_release" "helm_order" {
  name       = "ecommerce-helm-order"
  namespace  = "ecommerce-app"
  chart      = "../../helm/apps-order-service/"
        # version    = "0.1.0"
  timeout = 6000

  depends_on = [ helm_release.shared_gateway ]

}

resource "helm_release" "helm_frontend" {
  name       = "ecommerce-helm-frontend"
  namespace  = "ecommerce-app"
  chart      = "../../helm/apps-frontend/"
  version    = "0.1.0"
  timeout = 6000
  depends_on = [ helm_release.shared_gateway ]
}

resource "helm_release" "helm_payment" {
  name       = "ecommerce-helm-payment-2"
  namespace  = "ecommerce-app"
  chart      = "../../helm/apps-payment-service/"
  version    = "0.1.0"
  timeout = 6000
  depends_on = [ helm_release.shared_gateway ]
}

resource "helm_release" "helm_product" {
  name       = "ecommerce-helm-product-8"
  namespace  = "ecommerce-app"
  chart      = "../../helm/apps-product-service/"
  # version    = "0.2.0"
  timeout = 6000

  depends_on = [ helm_release.shared_gateway ]
}


// helm release charts for alb controller
resource "helm_release" "alb_controller" {
  name       = "alb-controller"
  namespace  = "azure-alb-system"
  chart      ="oci://mcr.microsoft.com/application-lb/charts/alb-controller"
   version    = "1.7.9"
  # version    = "0.1.0"
  timeout = 6000
    

  values = [yamlencode({

    namespaceCreation = {
      enabled = true
      namespace = "azure-alb-system"
    }

    albController = {
      namespace = "azure-alb-system"
      podIdentity = {
        clientID = azurerm_user_assigned_identity.alb_user_id.client_id
      }
    }
  })]

  depends_on = [module.aks, azurerm_federated_identity_credential.alb_federated_identity, module.agc]
}


// helm release chart for shared gateway
resource "helm_release" "shared_gateway" {
  name       = "shared-gateway"
  namespace  = "ecommerce-app"
  chart      = "../../helm/ecommerce-app/"
  timeout = 6000


  values = [yamlencode({
    gateway = {
      enabled = true
      name = "shared-gateway"
      agcID = module.agc.agc_lb_id
      frontendName = module.agc.agc_lb_frontend_name
    }
  })]

  depends_on = [helm_release.alb_controller]

}





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


module "agc" {
  source              = "../../modules/agc"
  location            = var.location
  resource_group_name = azurerm_resource_group.ecommerce_rg.name
  subnet_ids          = module.networking.subnet_ids
  alb_principal_id    = azurerm_user_assigned_identity.alb_user_id.principal_id

  depends_on = [ module.networking ]
}