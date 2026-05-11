variable "resource_group_name" {
    description = "The name of the resource group in which to create the AGC instance."
    type        = string
}

variable "location" {
    description = "The Azure region where the AGC instance will be deployed."
    type        = string
}

variable "subnet_ids" {
    description = "A map of subnet IDs for the AGC instance."
    type        = map(string)
}

variable "alb_principal_id" {
    description = "The principal ID of the ALB's managed identity."
    type        = string
}



