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

variable "vm_admin_name" {
    description = "The administrator username for the virtual machine."
    type        = string
}

variable "vm_admin_password" {
    description = "The administrator password for the virtual machine."
    type        = string
    sensitive   = true
}

variable "subnet_ids" {
    description = "The IDs of the subnets for the virtual machine."
    type        = map(string)
}
