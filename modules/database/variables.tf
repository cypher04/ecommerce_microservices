variable "resource_group_name" {
  description = "The name of the resource group in which to create the PostgreSQL flexible server."
  type        = string
}

variable "location" {
  description = "The location/region where the PostgreSQL flexible server will be created."
  type        = string
}

variable "admin_username" {
    description = "The administrator username for the PostgreSQL flexible server."
    type        = string
}

variable "admin_password" {
    description = "The administrator password for the PostgreSQL flexible server."
    type        = string
    sensitive   = true
}

variable "virtual_network_link_name" {
    description = "The name of the virtual network link for the PostgreSQL flexible server."
    type        = string
}

variable "subnet_prefixes" {
    description = "The address prefixes for the subnet."
    type        = map(string)
}

variable "subnet_ids" {
    description = "The IDs of the subnets for the PostgreSQL flexible server."
    type        = map(string)
}

variable "private_dns_zone_id" {
    description = "The ID of the private DNS zone for the PostgreSQL flexible server."
    type        = string
}