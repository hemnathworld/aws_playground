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

resource "azurerm_user_assigned_identity" "ama_identity" {
  name                = "ama-agent-identity"
  resource_group_name = var.resourcegroupname
  location            = var.location
}

resource "azurerm_monitor_data_collection_rule" "example" {
  name                = "ama-crossplatform-dcr"
  location            = var.resourcegroupname
  resource_group_name = var.location

  destinations {
    log_analytics {
      name                  = "amaloganalytics"
      workspace_resource_id = var.workspaceid
    }
  }

  data_flows {
    streams      = ["Microsoft-Perf"]
    destinations = ["amaloganalytics"]
  }

  data_flows {
    streams      = ["Microsoft-Syslog"]
    destinations = ["amaloganalytics"]
  }

  # Windows Performance Counters
  data_sources {
    performance_counter {
      name                          = "windows-perf"
      streams                       = ["Microsoft-Perf"]
      sampling_frequency_in_seconds = 60
      counter_specifiers            = [
        "\\Processor(_Total)\\% Processor Time",
        "\\Memory\\Available MBytes"
      ]
      filter_specification {
        name   = "windowsFilter"
        filter = "OS == 'Windows'"
      }
    }
  }

  # Linux Performance Counters
  data_sources {
    performance_counter {
      name                          = "linux-perf"
      streams                       = ["Microsoft-Perf"]
      sampling_frequency_in_seconds = 60
      counter_specifiers            = [
        "\\LogicalDisk(/)\\% Free Space",
        "\\Memory\\Available Bytes"
      ]
      filter_specification {
        name   = "linuxFilter"
        filter = "OS == 'Linux'"
      }
    }
  }

  # Linux Syslog Collection
  data_sources {
    syslog {
      name    = "linux-syslog"
      streams = ["Microsoft-Syslog"]
      facility_names = [
        "auth",
        "cron",
        "daemon",
        "syslog"
      ]
      log_levels = ["Error", "Critical", "Alert", "Emergency"]
      filter_specification {
        name   = "syslogFilter"
        filter = "OS == 'Linux'"
      }
    }
  }
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
      value = true
    }
    userAssignedIdentityResourceId = {
      value = azurerm_user_assigned_identity.ama_identity.id
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


resource "azurerm_monitor_data_collection_endpoint" "dc-endpoint" {
  name                          = "ama-datacollection-endpoint"
  resource_group_name           = <resource group name>
  location                      = <location>
  description                   = "monitor_data_collection_endpoint"
}


resource "azurerm_monitor_data_collection_rule_association" "dcr_assoc" {
  name                    = "vm-dcr-association"
  target_resource_id      = azurerm_linux_virtual_machine.vm.id
  data_collection_rule_id = azurerm_monitor_data_collection_rule.dcr.id
  data_collection_endpoint_id = 
}

https://learn.microsoft.com/en-us/azure/governance/policy/samples/built-in-policies

[Preview]: Configure system-assigned managed identity to enable Azure Monitor assignments on VMs
Configure Linux virtual machines to run Azure Monitor Agent with system-assigned managed identity-based authentication
Configure Windows virtual machines to run Azure Monitor Agent using system-assigned managed identity
Configure Windows Machines to be associated with a Data Collection Rule or a Data Collection Endpoint
Configure Linux Machines to be associated with a Data Collection Rule or a Data Collection Endpoint


/subscriptions/a5dd051b-df10-4969-a584-b416c4dfa6c6/resourceGroups/ama-log-analytics-rg/providers/Microsoft.ManagedIdentity/userAssignedIdentities/ama-testuser

/subscriptions/a5dd051b-df10-4969-a584-b416c4dfa6c6/resourceGroups/ama-log-analytics-rg/providers/Microsoft.Insights/dataCollectionRules/ama-agent-dcr


userAssignedManagedIdentityResourceGroup
userAssignedManagedIdentityName
