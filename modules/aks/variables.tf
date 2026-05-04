variable "resource_group_name" {
    description = "The name of the resource group where the Log Analytics Workspace will be created."
    type        = string
}

variable "location" {
    description = "The Azure region where the Log Analytics Workspace will be created."
    type        = string
}

variable "log_analytics_id" {
    description = "The ID of the Log Analytics Workspace to link with the AKS cluster."
    type        = string
}

variable "acr_id" {
    description = "The ID of the Azure Container Registry to link with the AKS cluster."
    type        = string
}

# variable "app_gateway_id" {
#     description = "The ID of the Application Gateway to link with the AKS cluster."
#     type        = string
# }

variable "admin_username" {
    description = "The admin username for the AKS cluster."
    type        = string
}

variable "admin_password" {
    description = "The admin password for the AKS cluster."
    type        = string
    sensitive   = true
}

variable "db_host" {
    description = "The hostname of the PostgreSQL database."
    type        = string
}

variable "db_name" {
    description = "The name of the PostgreSQL database."
    type        = string
}

variable "db_password" {
    description = "The password for the PostgreSQL database."
    type        = string
    sensitive   = true
}

variable "db_user" {
    description = "The username for the PostgreSQL database."
    type        = string
}

# variable "alb_identity_id" {
#     description = "The ID of the user-assigned identity for the Application Gateway Ingress Controller."
#     type        = string 
# }

variable "oidc_issuer_url" {
    description = "The OIDC issuer URL for the AKS cluster, used for federated identity."
    type        = string
}

variable "subnet_ids" {
    description = "A map of subnet IDs for the AKS cluster."
    type        = map(string)
}


variable "vnet_id" {
    description = "The ID of the virtual network where the AKS cluster will be deployed."
    type        = string
}