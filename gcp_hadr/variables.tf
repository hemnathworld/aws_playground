variable "project_id" {
  description = "The ID of the GCP project where the bucket will be created"
  type        = string
}

variable "region" {
  description = "Primary region for the Cloud Storage bucket"
  type        = string
  default     = "us-central1"
}

variable "bucket_name" {
  description = "The name of the Cloud Storage bucket"
  type        = string
}