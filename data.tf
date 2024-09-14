data "aws_iam_policy_document" "deny_ec2_vpc_actions" {
  version = "2012-10-17"

  statement {
    effect = "Deny"
    actions = [
      "ec2:TerminateInstances",
      "ec2:StopInstances"
    ]
    resources = ["*"]
  }

  statement {
    effect = "Deny"
    actions = [
      "ec2:DeleteVpc"
    ]
    resources = ["*"]
  }
}
