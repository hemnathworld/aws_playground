data "aws_iam_policy_document" "bucket_policy" {
  statement {	
    sid       = "AllowFullS3Access"
    actions   = ["s3:ListAllMyBuckets"]
    resources = ["*"]
  }
}


resource "aws_iam_policy" "policy" {
  name        = example_policy
  path        = "/"
  policy = data.aws_iam_policy_document.bucket_policy.json
}
