resource "aws_iam_role" "ec2_role" {
  count    = var.region == "us-west-1" ? 1 : 0
  name = "ec2_dynamo_s3_access_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_policy" "ec2_policy" {
  count    = var.region == "us-west-1" ? 1 : 0
  name   = "ec2_dynamo_s3_access_policy"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = [
          "dynamodb:*",
          "s3:*"
        ],
        Effect   = "Allow",
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ec2_attach_policy" {
  count    = var.region == "us-west-1" ? 1 : 0
  role       = aws_iam_role.ec2_role[count.index].name
  policy_arn = aws_iam_policy.ec2_policy[count.index].arn
}

resource "aws_iam_instance_profile" "ec2_profile" {
  count    = var.region == "us-west-1" ? 1 : 0
  name = "ec2_instance_profile"
  role = aws_iam_role.ec2_role[count.index].name
}