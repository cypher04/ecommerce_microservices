output "agc_frontend_fqdn" {
    value = module.agc.agc_lb_frontend_fqdn
    description = "The FQDN of the Application Gateway frontend"
}