resource "azurerm_application_load_balancer" "agc_lb" {
    name                = "${var.resource_group_name}-agc-lb"
    location            = var.location
    resource_group_name = var.resource_group_name
}

resource "azurerm_application_load_balancer_subnet_association" "agc_lb_subnet_association" {
    name = "${var.resource_group_name}-agc-lb-subnet-association"
    application_load_balancer_id = azurerm_application_load_balancer.agc_lb.id
    subnet_id                    = var.subnet_ids["agc"]
}

resource "azurerm_application_load_balancer_frontend" "agc_lb_frontend" {
    name                          = "${var.resource_group_name}-agc-lb-frontend"
    application_load_balancer_id  = azurerm_application_load_balancer.agc_lb.id
}

resource "azurerm_web_application_firewall_policy" "agc_waf_policy" {
    name                = "${var.resource_group_name}-agc-waf-policy"
    resource_group_name = var.resource_group_name
    location            = var.location

    managed_rules {
      managed_rule_set {
        type = "Microsoft_DefaultRuleSet"
        version = "2.1"
      }
    }

    policy_settings {
      enabled = true
      mode = "Detection"
    }
}

resource "azurerm_application_load_balancer_security_policy" "agc_lb_security_policy" {
    name                = "${var.resource_group_name}-agc-lb-security-policy"
    location            = var.location
    application_load_balancer_id = azurerm_application_load_balancer.agc_lb.id
    web_application_firewall_policy_id = azurerm_web_application_firewall_policy.agc_waf_policy.id
}

// Role assignment for ALB to allow it to manage its configuration and security policies

resource "azurerm_role_assignment" "alb_subnet_network_contributor" {
    scope                = azurerm_application_load_balancer.agc_lb.id
    role_definition_name = "Network Contributor"
    principal_id         = var.alb_principal_id
}

resource "azurerm_role_assignment" "alb_configuration_manager_role_assignment" {
    scope                = azurerm_application_load_balancer.agc_lb.id
    role_definition_name = "AppGw for Containers Configuration Manager"
    principal_id         = var.alb_principal_id
}


