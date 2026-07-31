terraform {
backend "azurerm" {
    resource_group_name  = "ecommerceprojectdev-rg"
    storage_account_name = "ecommerceprojectstatedev"
    container_name       = "ecommerceprojectdev-tfstate"
    key                  = "dev.terraform.tfstate"
  }     
}
