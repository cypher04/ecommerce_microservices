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

variable "app_gateway_id" {
    description = "The ID of the Application Gateway to link with the AKS cluster."
    type        = string
}

variable "admin_username" {
    description = "The admin username for the AKS cluster."
    type        = string
}

variable "admin_password" {
    description = "The admin password for the AKS cluster."
    type        = string
    sensitive   = true
}

variable "dbhostname" {
    description = "The hostname of the PostgreSQL database."
    type        = string
}

variable "dbname" {
    description = "The name of the PostgreSQL database."
    type        = string
}

variable "dbpassword" {
    description = "The password for the PostgreSQL database."
    type        = string
    sensitive   = true
}

variable "dbusername" {
    description = "The username for the PostgreSQL database."
    type        = string
}
