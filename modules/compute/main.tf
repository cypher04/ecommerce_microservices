resource "azurerm_container_registry" "ecommerce_acr" {
  name                = var.acr_name
  resource_group_name = var.resource_group_name
  location            = var.location
  sku = "Premium"
}

resource "azurerm_network_interface" "vm_nic" {
  name                = "${var.resource_group_name}-vm-nic"
  location            = var.location
  resource_group_name = var.resource_group_name
  ip_configuration {
    name                          = "internal"
    subnet_id                     = var.subnet_ids["web"]
    private_ip_address_allocation = "Dynamic"
  }
  
}

resource "azurerm_linux_virtual_machine" "vm" {
  name                = "${var.resource_group_name}-vm"
  resource_group_name = var.resource_group_name
  location            = var.location
  size                = "Standard_B1s"
  admin_username      = var.vm_admin_name
  admin_password      = var.vm_admin_password
  network_interface_ids = [azurerm_network_interface.vm_nic.id]
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  admin_ssh_key {
    username   = var.vm_admin_name
    public_key = file("~/.ssh/id_rsa.pub")
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-LTS"
    version   = "latest"
  }
}


