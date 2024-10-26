provider "aws" {
  region = var.region  
}

# Data source to get the current AWS account ID
data "aws_caller_identity" "current" {}

# Construct bucket name by appending region to base name
locals {
  bucket_name = "${var.bucket_name}-${var.region}"
}

# S3 bucket creation with default encryption
resource "aws_s3_bucket" "main" {
  bucket = local.bucket_name

  lifecycle {
    prevent_destroy = true
  }
}

# S3 Bucket Encryption configuration
resource "aws_s3_bucket_server_side_encryption_configuration" "main" {
  bucket = aws_s3_bucket.main.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# S3 Bucket Versioning
resource "aws_s3_bucket_versioning" "main" {
  bucket = aws_s3_bucket.main.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Bucket Policy for the Destination Bucket
resource "aws_s3_bucket_policy" "destination_policy" {
  count = var.enable_replication ? 0 : 1
  bucket = "${var.bucket_name}-us-east-1"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.bucket_name}-us-west-1-replication-role"
        }
        Action = "s3:ReplicateObject"
        Resource = "arn:aws:s3:::${var.bucket_name}-us-east-1/*"
      },
      {
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.bucket_name}-us-west-1-replication-role"
        }
        Action = "s3:ReplicateDelete"
        Resource = "arn:aws:s3:::${var.bucket_name}-us-east-1/*"
      }
    ]
  })
}


# IAM Role and Policy for S3 Replication, only created if replication is enabled
resource "aws_iam_role" "replication_role" {
  count = var.enable_replication ? 1 : 0
  name  = "${local.bucket_name}-replication-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "s3.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_policy" "replication_policy" {
  count  = var.enable_replication ? 1 : 0
  name   = "${local.bucket_name}-replication-policy"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetReplicationConfiguration",
          "s3:ListBucket"
        ]
        Resource = [aws_s3_bucket.main.arn]
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObjectVersion",
          "s3:GetObjectVersionAcl"
        ]
        Resource = "${aws_s3_bucket.main.arn}/*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:ReplicateObject",
          "s3:ReplicateDelete"
        ]
        Resource = "arn:aws:s3:::${var.bucket_name}-us-east-1/*"
      },
      {
        Effect = "Allow",
        Action = "s3:PutReplicationConfiguration",
        Resource = [aws_s3_bucket.main.arn]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "replication_attachment" {
  count      = var.enable_replication ? 1 : 0
  role       = aws_iam_role.replication_role[count.index].name
  policy_arn = aws_iam_policy.replication_policy[count.index].arn
}

# S3 Bucket Replication Configuration
resource "aws_s3_bucket_replication_configuration" "replication" {
  count  = var.enable_replication ? 1 : 0
  bucket = aws_s3_bucket.main.id
  role   = aws_iam_role.replication_role[count.index].arn

  rule {
    id     = "ReplicationRule"
    status = "Enabled"

    destination {
      # Reference the secondary bucket for replication
      bucket        = "arn:aws:s3:::${var.bucket_name}-us-east-1"
      storage_class = "STANDARD"
    }
  }
}

# Upload index.html file to the S3 bucket
resource "aws_s3_bucket_object" "index_html" {
  count  = var.enable_replication ? 1 : 0
  bucket = local.bucket_name
  key    = "index.html"  # The name of the file in the bucket
  source = "html/index.html"  # Local path to your index.html file

  # Content type for HTML files
  content_type = "text/html"

  etag = filemd5("html/index.html") 
}

