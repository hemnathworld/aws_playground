# List of Policy Names to be assigned
variable "policy_names" {
  type    = list(string)
  default = [
    "Audit VMs that do not use managed disks",
    "Require secure transfer for storage accounts"
  ]
}


variable "policy_parameters" {
  type = map(map(any))
  default = {
    "[Preview]: Assign Built-In User-Assigned Managed Identity to Virtual Machines" = jsonencode({
      "bringYourOwnUserAssignedManagedIdentity" = false
    })
    "[Preview]: Assign Built-In User-Assigned Managed Identity to Virtual Machine Scale Sets" = jsonencode({
      "bringYourOwnUserAssignedManagedIdentity" = false
    })
    "Configure Windows virtual machines to run Azure Monitor Agent with user-assigned managed identity-based authentication" = jsonencode({
      "bringYourOwnUserAssignedManagedIdentity" = false
    })
    "Configure Windows virtual machine scale sets to run Azure Monitor Agent with user-assigned managed identity-based authentication" = jsonencode({
      "bringYourOwnUserAssignedManagedIdentity" = false
    })
    "Configure Windows Machines to be associated with a Data Collection Rule or a Data Collection Endpoint" = jsonencode({
      "dcrResourceId"     = "/subscriptions/xxxx/resourceGroups/rg-name/providers/Microsoft.Insights/dataCollectionRules/dcr-nam"
    })
    "Configure Linux virtual machines to run Azure Monitor Agent with user-assigned managed identity-based authentication" = jsonencode({
       "bringYourOwnUserAssignedManagedIdentity" = false
    })
    "Configure Linux virtual machine scale sets to run Azure Monitor Agent with user-assigned managed identity-based authentication" = jsonencode({
       "bringYourOwnUserAssignedManagedIdentity" = false
    })
    "Configure Linux Machines to be associated with a Data Collection Rule or a Data Collection Endpoint" = jsonencode({
      "dcrResourceId"     = "/subscriptions/xxxx/resourceGroups/rg-name/providers/Microsoft.Insights/dataCollectionRules/dcr-nam"
    })
  }
}
