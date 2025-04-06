# Create a map of policies
locals {
  policy_map = { for idx, name in var.policy_names : name => idx }
}

resource "random_id" "suffix" {
  for_each = local.policy_map
  byte_length = 2  # 2 bytes = 4 hex chars
}

# Data source to get the policy definition ID for the built-in policy
data "azurerm_policy_definition_built_in" "monitor_agent" {
  for_each = toset(var.policy_names)
  display_name     = each.value
}

# Data source to get management group ID (you can replace this with your actual management group ID)
data "azurerm_management_group" "my_management_group" {
  name = var.env
}

# Policy Assignment to enforce the deployment of Azure Monitor Agent at the management group level
resource "azurerm_policy_assignment" "monitor_agent_assignment" {
  for_each = data.azurerm_policy_definition.policy_definitions
  name                 = "asg-${random_id.suffix[each.key].hex}"
  scope                = data.azurerm_management_group.my_management_group.id
  policy_definition_id = each.value.id
  display_name         = "Deploy Azure Monitor Agent on VMs"
  description          = "This policy ensures that the Azure Monitor Agent is automatically installed on virtual machines."
  enforcement_mode     = "Default"
  #parameters = jsonencode(lookup(var.policy_parameters, each.key, {}))
  parameters = jsonencode({
    bringYourOwnUserAssignedManagedIdentity = {
      value = false
    }
  })
}


resource "azurerm_network_interface" "nic" {
  name                = "${var.vm_name}-nic"
  location            = var.location
  resource_group_name = var.resource_group_name

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_windows_virtual_machine" "vm" {
  name                  = var.vm_name
  resource_group_name   = var.resource_group_name
  location              = var.location
  size                  = "Standard_B1s"
  admin_username        = var.admin_username
  admin_password        = var.admin_password
  network_interface_ids = [azurerm_network_interface.nic.id]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    name                 = "${var.vm_name}-osdisk"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2019-Datacenter"
    version   = "latest"
  }
}
