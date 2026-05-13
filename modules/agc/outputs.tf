output "agc_lb_id" {
    description = "The ID of the Application Load Balancer for AGC"
    value       = azurerm_application_load_balancer.agc_lb.id
}

output "agc_lb_frontend_id" {
    description = "The ID of the Application Load Balancer frontend for AGC"
    value       = azurerm_application_load_balancer_frontend.agc_lb_frontend.id
}

output "agc_lb_frontend_name" {
    description = "The name of the Application Load Balancer frontend for AGC"
    value       = azurerm_application_load_balancer_frontend.agc_lb_frontend.name
}

output "agc_lb_frontend_fqdn" {
    description = "The FQDN of the Application Load Balancer frontend for AGC"
    value       = azurerm_application_load_balancer_frontend.agc_lb_frontend.fully_qualified_domain_name
}

output "agc_waf_policy_id" {
    description = "The ID of the Web Application Firewall policy for AGC"
    value       = azurerm_web_application_firewall_policy.agc_waf_policy.id
}

output "agc_lb_security_policy_id" {
    description = "The ID of the Application Load Balancer security policy for AGC"
    value       = azurerm_application_load_balancer_security_policy.agc_lb_security_policy.id
}