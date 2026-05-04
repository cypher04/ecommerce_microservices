variable "resource_group_name" {
  description = "The name of the resource group"
  type        = string
}

variable "location" {
  description = "The location of the resources"
  type        = string
}
variable "subnet_prefixes" {
  description = "The prefixes of the subnets"
  type        = map(string) 
}

variable "subnet_ids" {
  description = "The IDs of the subnets"
  type        = map(string) 
}

# variable "app_gateway_public_ip_id" {
#   description = "The ID of the public IP for the Application Gateway"
#   type        = string
# }

variable "acr_id" {
  description = "The ID of the Azure Container Registry"
  type        = string
}

variable "vnet_id" {
  description = "The ID of the virtual network"
  type        = string
}
