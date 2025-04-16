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

resource "azurerm_virtual_machine_extension" "ama" {
 name                       = "testextension"
 virtual_machine_id         = azurerm_windows_virtual_machine.vm.id
 publisher                  = "Microsoft.Azure.Monitor"
 type                       = "AzureMonitorWindowsAgent"
 type_handler_version       = "1.10"
 auto_upgrade_minor_version = "true"
 tags = merge(var.tags, tomap({ "firstapply" = timestamp() }))
 lifecycle {
   ignore_changes = [tags]
 }
}

resource "azurerm_monitor_data_collection_rule" "rule1" {
 name                = <name>
 location            = var.location
 resource_group_name = var.resource_group_name
 depends_on          = [azurerm_virtual_machine_extension.ama]
 
 destinations {
   log_analytics {
     workspace_resource_id = var.log_analytics_workspace
     name                  = "log-analytics"
   }
 }
 
 data_flow {
   streams      = ["Microsoft-Event"]
   destinations = ["log-analytics"]
 }
 
 data_sources {
   windows_event_log {
     streams = ["Microsoft-Event"]
     x_path_queries = ["Application!*[System[(Level=1 or Level=2 or Level=3 or Level=4 or Level=0 or Level=5)]]",
       "Security!*[System[(band(Keywords,13510798882111488))]]",
     "System!*[System[(Level=1 or Level=2 or Level=3 or Level=4 or Level=0 or Level=5)]]"]
     name = "eventLogsDataSource"
   }
 }
}
 
# data collection rule association
 
resource "azurerm_monitor_data_collection_rule_association" "dcra1" {
 name                    = "testvm-dcra"
 target_resource_id      = azurerm_windows_virtual_machine.vm.id
 data_collection_rule_id = azurerm_monitor_data_collection_rule.rule1.id
}
