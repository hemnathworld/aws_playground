# Data source to get the policy definition ID for the built-in policy
data "azurerm_policy_definition_built_in" "monitor_agent" {
  for_each = toset(var.policy_names)
  name     = each.value
}

# Data source to get management group ID (you can replace this with your actual management group ID)
data "azurerm_management_group" "my_management_group" {
  name = var.env
}

# Policy Assignment to enforce the deployment of Azure Monitor Agent at the management group level
resource "azurerm_policy_assignment" "monitor_agent_assignment" {
  for_each = data.azurerm_policy_definition.policy_definitions
  name                 = "deploy-azure-monitor-agent"
  scope                = data.azurerm_management_group.my_management_group.id
  policy_definition_id = each.value.id
  display_name         = "Deploy Azure Monitor Agent on VMs"
  description          = "This policy ensures that the Azure Monitor Agent is automatically installed on virtual machines."
  enforcement_mode     = "Default"
}
