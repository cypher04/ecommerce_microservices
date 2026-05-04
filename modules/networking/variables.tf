variable "acr_name" {
  description = "The name of the Azure Container Registry."
  type        = string
}

variable "resource_group_name" {
  description = "The name of the resource group in which to create the Azure Container Registry."
  type        = string
}

variable "location" {
  description = "The Azure region where the Azure Container Registry will be created."
  type        = string
}

variable "address_space" {
    description = "The address space for the virtual network."
    type        = list(string)
}

variable "subnet_prefixes" {
    description = "The address prefixes for the subnet."
    type        = map(string)
}

variable "oidc_issuer_url" {
    description = "The URL of the OpenID Connect (OIDC) issuer."
    type        = string
}