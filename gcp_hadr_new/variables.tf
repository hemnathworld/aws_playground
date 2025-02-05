variable "region" {
  description = "GCP region"
  type        = string
}

variable "bucket_name" {
  description = "Name of the Cloud Storage S3 bucket"
  type        = string
}

variable "project_id" {
  type = string
}

variable "source_project_id" {
  type = string
}


variable "topic_name" {
  description = "The name of the Pub/Sub topic"
  type        = string
}

variable "subscriber_name" {
  description = "The name of the Pub/Sub subscriber"
  type        = string
}

variable "secondary_project_number" {
  description = "Project Number of the secondary region"
  type        = number
  default = "303082797220"
}

variable "source_bucket_name" {
  description = "Bucket Number of the primary region"
  type        = string
}
