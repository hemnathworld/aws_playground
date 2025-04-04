# List of Policy Names to be assigned
variable "policy_names" {
  type    = list(string)
  default = [
    "Audit VMs that do not use managed disks",
    "Require secure transfer for storage accounts"
  ]
}
