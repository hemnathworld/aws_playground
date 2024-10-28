variable "region" {
  description = "AWS region for the primary RDS instance"
  type        = string
}

variable "bucket_name" {
  description = "Base name of the S3 bucket"
  type        = string
}

variable "enable_replication" {
  description = "Enable Cross-Region Replication"
  type        = bool
}


variable "dynamodb_table_name" {
  description = "DynamoDB table name"
  type        = string
}

variable "ami" {
  description = "Instance AMI ID"
  type        = string
}

variable "subnet_id" {
  description = "Instance subnet_id"
  type        = string
}

variable "private_ip" {
  description = "Private IP address for EC2 instance"
  type        = string
}

variable "primary_vpc_id" {
  description = "The VPC ID for the Primary region"
  type        = string
}

variable "secondary_vpc_id" {
  description = "The VPC ID for the Secondary  region"
  type        = string
}

variable "private_zone_name" {
  description = "The name of the private hosted zone"
  type        = string
}