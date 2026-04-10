variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Location of the resource group"
  type        = string
}

variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Deployment environment (e.g., dev, prod)"
  type        = string
}

variable "address_space" {
  description = "Address space for the virtual network"
  type        = list(string)
}

variable "subnet_prefixes" {
  description = "Map of subnet names to their respective CIDR prefixes"
  type        = map(string)
}

variable "acr_name" {
  description = "Name of the Azure Container Registry"
  type        = string
}

variable "aks_cluster_name" {
  description = "Name of the Azure Kubernetes Service cluster"
  type        = string
}

variable "admin_username" {
    description = "Admin username for AKS cluster"
    type        = string
}

variable "admin_password" {
    description = "Admin password for AKS cluster"
    type        = string
    sensitive   = true
}