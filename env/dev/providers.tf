terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "4.67.0"
    }

    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "3.0.1"
  }

    helm = {
      source  = "hashicorp/helm"
      version = "3.1.1"
}
}
}

provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}

provider "kubernetes" {
    host                   = module.aks.host
    client_certificate     = base64decode(module.aks.client_certificate)
    client_key             = base64decode(module.aks.client_key)
    cluster_ca_certificate = base64decode(module.aks.cluster_ca_certificate)
}

provider "helm" {
    kubernetes = {
        host                   = module.aks.host
        client_certificate     = base64decode(module.aks.client_certificate)
        client_key             = base64decode(module.aks.client_key)
        cluster_ca_certificate = base64decode(module.aks.cluster_ca_certificate)
    }
}




