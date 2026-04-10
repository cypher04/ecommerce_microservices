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