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
  default     = false
}

variable "subnet_ids" {
  description = "Identifier for the RDS database"
  type        = list
}

variable "db_identifier" {
  description = "Identifier for the RDS database"
  type        = string
}

variable "db_username" {
  description = "Username for the database"
  type        = string
}

variable "db_password" {
  description = "Password for the database"
  type        = string
  sensitive   = true
}
