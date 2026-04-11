variable "resource_group_name" {
    description = "The name of the resource group where the Log Analytics Workspace will be created."
    type        = string
}

variable "location" {
    description = "The Azure region where the Log Analytics Workspace will be created."
    type        = string
}

variable "subnet_prefixes" {
    description = "The address prefixes for the subnet."
    type        = map(string)
}

variable "vnet_id" {
    description = "The ID of the virtual network to link with the private DNS zone."
    type        = string
}

variable "flexible_server_id" {
    description = "The ID of the Azure Database for MySQL Flexible Server to link with the private endpoint."
    type        = string
}

variable "subnet_ids" {
    description = "A map of subnet IDs for the private endpoint."
    type        = map(string)
}