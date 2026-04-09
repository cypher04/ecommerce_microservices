resource "azurerm_resource_group" "ecommerce_rg" {
  name     = "${var.project_name}${var.environment}-rg"
  location = var.location


  tags = {
    project     = var.project_name
    environment = var.environment
  }
  
}




