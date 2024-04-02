terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
    }
  }
}
provider "azurerm" {
  features {

  }
}
resource "azurerm_resource_group" "devops" {
  name     = "devops"
  location = "West Europe"
  tags = {
    environment = "dev"
  }

}

resource "azurerm_virtual_network" "devops_vn" {
  name                = "devops_network"
  resource_group_name = azurerm_resource_group.devops.name
  location            = azurerm_resource_group.devops.location
  address_space       = ["10.123.0.0/16"]

  tags = {
    environment = "dev"
  }
}

resource "azurerm_subnet" "devops_subnet" {
  name                 = "devops_subnet"
  resource_group_name  = azurerm_resource_group.devops.name
  virtual_network_name = azurerm_virtual_network.devops_vn.name
  address_prefixes     = ["10.123.1.0/24"]
}

resource "azurerm_network_security_group" "devops_security_group" {
  name                = "devops_sec_g"
  location            = azurerm_resource_group.devops.location
  resource_group_name = azurerm_resource_group.devops.name
  tags = {
    environment = "dev"
  }
}

resource "azurerm_network_security_rule" "devops_security_rule" {
  name                        = "devops_s_r"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.devops.name
  network_security_group_name = azurerm_network_security_group.devops_security_group.name
}

resource "azurerm_subnet_network_security_group_association" "devops_s_network_sg_a" {
  subnet_id                 = azurerm_subnet.devops_subnet.id
  network_security_group_id = azurerm_network_security_group.devops_security_group.id
}

resource "azurerm_public_ip" "devops_public_ip" {
  name                = "devops_ip"
  resource_group_name = azurerm_resource_group.devops.name
  location            = azurerm_resource_group.devops.location
  allocation_method   = "Dynamic"

  tags = {
    environment = "dev"
  }
}

resource "azurerm_network_interface" "devops_network_interface" {
  name                = "devops_nic"
  location            = azurerm_resource_group.devops.location
  resource_group_name = azurerm_resource_group.devops.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.devops_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.devops_public_ip.id
  }

  tags = {
    environment = "dev"
  }
}
resource "azurerm_linux_virtual_machine" "devops_vm" {
  name                = "devops-machine"
  resource_group_name = azurerm_resource_group.devops.name
  location            = azurerm_resource_group.devops.location
  size                = "Standard_B1s"
  admin_username      = "adminuser"
  network_interface_ids = [
    azurerm_network_interface.devops_network_interface.id,
  ]
  custom_data = filebase64("customdata.tpl")
  admin_ssh_key {
    username   = "adminuser"
    public_key = file("./devopsazurekey.pub")
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }
  provisioner "local-exec" {
    command = templatefile("${var.host_os}-ssh-script.tpl", {
      hostname     = self.public_ip_address
      user         = "adminuser"
      identityfile = "./devopsazurekey"
    })
    interpreter = var.host_os=="linux" ?  ["bash", "-c"] : ["Powershell","-Command"]
  }
  tags = {
    environment = "dev"
  }
}

data "azurerm_public_ip" "devops_ip_data" {
  name                = azurerm_public_ip.devops_public_ip.name
  resource_group_name = azurerm_resource_group.devops.name
}
output "public_ip_address" {
    value = "${azurerm_linux_virtual_machine.devops_vm.name}: ${data.azurerm_public_ip.devops_ip_data.ip_address}"
  
}