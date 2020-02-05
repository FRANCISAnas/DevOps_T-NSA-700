####################################
##            VARIABLES
####################################

variable "prefix" {
  default = "t-nsa-700-gr-22"
}

variable "pubSSHkey" {
  default = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDcsdMX2DQYDTtDmud+eygYRegKzvXjRVx9B3T35B3jc5QBKZirkj50yFPhk7T/FGL9606L28Ap9/LMDXrs0jmslRo6o1OOxRmGMs3ePeHztxlaWps6RgRwGGK6A7yc9GBpuqq28KOoTw9h+XWLalfMLMhgM77lk4ZuKWWJXYJpQnMDat8WoZO4r/ibgFDTSx2GhufvpcuJnBqQrnG+FGx6FtOk75sYZ50vvGlnC64dGyIJidVEQS+sa3zzlQxpB/N9KQOPb2l5k1RZFDDnGT4nssWurBPqlvJ164cPcryzO06uwUmXFbAqZ+y/4L/Lu4mKlLpmXiVEbS+jqNObJLWp jonas@DESKTOP-9Q3MEAS"
}

variable "private_ip_gitlab" {
  default = "10.0.2.10"
}
variable "private_ip_db" {
  default = "10.0.2.11"
}
variable "private_ip_front" {
  default = "10.0.2.12"
}
variable "private_ip_back" {
  default = "10.0.2.13"
}



####################################
##            GENERAL
####################################

provider "azurerm" {
  version         = "=1.41.0"
  subscription_id = "be621281-7c9f-41d6-ae3a-21ebe7cf687f"
}

resource "azurerm_resource_group" "main" {
  name     = "${var.prefix}-resources"
  location = "westeurope"
}

resource "azurerm_virtual_network" "main" {
  name                = "${var.prefix}-network"
  address_space       = ["10.0.0.0/16"]
  location            = "${azurerm_resource_group.main.location}"
  resource_group_name = "${azurerm_resource_group.main.name}"
}

resource "azurerm_subnet" "internal" {
  name                 = "internal"
  resource_group_name  = "${azurerm_resource_group.main.name}"
  virtual_network_name = "${azurerm_virtual_network.main.name}"
  address_prefix       = "10.0.2.0/24"
}


####################################
##            DB
####################################

resource "azurerm_public_ip" "db" {
  name                = "${var.prefix}-db-nic"
  location            = "${azurerm_resource_group.main.location}"
  resource_group_name = "${azurerm_resource_group.main.name}"
  allocation_method   = "Static"
}


resource "azurerm_network_interface" "db" {
  name                = "${var.prefix}-db-nic"
  location            = "${azurerm_resource_group.main.location}"
  resource_group_name = "${azurerm_resource_group.main.name}"

  ip_configuration {
    name                          = "db"
    subnet_id                     = "${azurerm_subnet.internal.id}"
    private_ip_address_allocation = "Static"
    private_ip_address            = "${var.private_ip_db}"
    public_ip_address_id          = "${azurerm_public_ip.db.id}"
  }
}

resource "azurerm_virtual_machine" "db" {
  name                  = "${var.prefix}-db-vm"
  location              = "${azurerm_resource_group.main.location}"
  resource_group_name   = "${azurerm_resource_group.main.name}"
  network_interface_ids = ["${azurerm_network_interface.db.id}"]
  vm_size               = "Standard_B1ls"

  # Uncomment this line to delete the OS disk automatically when deleting the VM
  delete_os_disk_on_termination = true


  # Uncomment this line to delete the data disks automatically when deleting the VM
  delete_data_disks_on_termination = true

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }
  storage_os_disk {
    name              = "db"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }
  os_profile {
    computer_name  = "db"
    admin_username = "jonas"
    admin_password = "Jonas1!"
    custom_data    = "${file("scripts/createSSH.sh")}"
  }
  os_profile_linux_config {
    disable_password_authentication = false
    ssh_keys {
      path     = "/home/jonas/.ssh/authorized_keys"
      key_data = "${var.pubSSHkey}"
    }
  }
}

####################################
##            FRONT
####################################

resource "azurerm_public_ip" "front" {
  name                = "${var.prefix}-front-nic"
  location            = "${azurerm_resource_group.main.location}"
  resource_group_name = "${azurerm_resource_group.main.name}"
  allocation_method   = "Static"
}

resource "azurerm_network_interface" "front" {
  name                = "${var.prefix}-front-nic"
  location            = "${azurerm_resource_group.main.location}"
  resource_group_name = "${azurerm_resource_group.main.name}"

  ip_configuration {
    name                          = "gitlab"
    subnet_id                     = "${azurerm_subnet.internal.id}"
    private_ip_address_allocation = "Static"
    private_ip_address            = "${var.private_ip_front}"
    public_ip_address_id          = "${azurerm_public_ip.front.id}"
  }
}

resource "azurerm_virtual_machine" "front" {
  name                  = "${var.prefix}-front-vm"
  location              = "${azurerm_resource_group.main.location}"
  resource_group_name   = "${azurerm_resource_group.main.name}"
  network_interface_ids = ["${azurerm_network_interface.front.id}"]
  vm_size               = "Standard_B1ls"

  # Uncomment this line to delete the OS disk automatically when deleting the VM
  delete_os_disk_on_termination = true


  # Uncomment this line to delete the data disks automatically when deleting the VM
  delete_data_disks_on_termination = true

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }
  storage_os_disk {
    name              = "front"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }
  os_profile {
    computer_name  = "front"
    admin_username = "jonas"
    admin_password = "Jonas1!"
    custom_data    = "${file("scripts/createSSH.sh")}"
  }
  os_profile_linux_config {
    disable_password_authentication = false
    ssh_keys {
      path     = "/home/jonas/.ssh/authorized_keys"
      key_data = "${var.pubSSHkey}"
    }
  }
}



####################################
##            BACK
####################################

resource "azurerm_public_ip" "back" {
  name                = "${var.prefix}-back-nic"
  location            = "${azurerm_resource_group.main.location}"
  resource_group_name = "${azurerm_resource_group.main.name}"
  allocation_method   = "Static"
}

resource "azurerm_network_interface" "back" {
  name                = "${var.prefix}-back-nic"
  location            = "${azurerm_resource_group.main.location}"
  resource_group_name = "${azurerm_resource_group.main.name}"

  ip_configuration {
    name                          = "gitlab"
    subnet_id                     = "${azurerm_subnet.internal.id}"
    private_ip_address_allocation = "Static"
    private_ip_address            = "${var.private_ip_back}"
    public_ip_address_id          = "${azurerm_public_ip.back.id}"
  }
}

resource "azurerm_virtual_machine" "back" {
  name                  = "${var.prefix}-back-vm"
  location              = "${azurerm_resource_group.main.location}"
  resource_group_name   = "${azurerm_resource_group.main.name}"
  network_interface_ids = ["${azurerm_network_interface.back.id}"]
  vm_size               = "Standard_B1ls"

  # Uncomment this line to delete the OS disk automatically when deleting the VM
  delete_os_disk_on_termination = true


  # Uncomment this line to delete the data disks automatically when deleting the VM
  delete_data_disks_on_termination = true

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }
  storage_os_disk {
    name              = "back"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }
  os_profile {
    computer_name  = "back"
    admin_username = "jonas"
    admin_password = "Jonas1!"
    custom_data    = "${file("scripts/createSSH.sh")}"
  }
  os_profile_linux_config {
    disable_password_authentication = false
    ssh_keys {
      path     = "/home/jonas/.ssh/authorized_keys"
      key_data = "${var.pubSSHkey}"
    }
  }
}



####################################
##            GITLAB
####################################

resource "azurerm_public_ip" "gitlab" {
  name                = "${var.prefix}-gitlab-nic"
  location            = "${azurerm_resource_group.main.location}"
  resource_group_name = "${azurerm_resource_group.main.name}"
  allocation_method   = "Static"
}

resource "azurerm_network_interface" "gitlab" {
  name                = "${var.prefix}-gitlab-nic"
  location            = "${azurerm_resource_group.main.location}"
  resource_group_name = "${azurerm_resource_group.main.name}"

  ip_configuration {
    name                          = "gitlab"
    subnet_id                     = "${azurerm_subnet.internal.id}"
    private_ip_address_allocation = "Static"
    private_ip_address            = "${var.private_ip_gitlab}"
    public_ip_address_id          = "${azurerm_public_ip.gitlab.id}"
  }
}

resource "azurerm_virtual_machine" "gitlab" {
  name                  = "${var.prefix}-gitlab-vm"
  location              = "${azurerm_resource_group.main.location}"
  resource_group_name   = "${azurerm_resource_group.main.name}"
  network_interface_ids = ["${azurerm_network_interface.gitlab.id}"]
  vm_size               = "Standard_B1ms"

  # Uncomment this line to delete the OS disk automatically when deleting the VM
  delete_os_disk_on_termination = true


  # Uncomment this line to delete the data disks automatically when deleting the VM
  delete_data_disks_on_termination = true

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }
  storage_os_disk {
    name              = "gitlab"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }
  os_profile {
    computer_name  = "gitlab"
    admin_username = "jonas"
    admin_password = "Jonas1!"
    custom_data    = "${file("scripts/setupGitlab.sh")}"
  }
  os_profile_linux_config {
    disable_password_authentication = false
    ssh_keys {
      path     = "/home/jonas/.ssh/authorized_keys"
      key_data = "${var.pubSSHkey}"
    }
  }
  depends_on = [
    "azurerm_virtual_machine.db",
    "azurerm_virtual_machine.front",
    "azurerm_virtual_machine.back"
  ]
}
