variable "region" {
  description = "GCP region"
  type        = string
}

variable "source_bucket_name" {
  description = "Name of the Cloud Storage primary bucket"
  type        = string
}

variable "target_bucket_name" {
  description = "Name of the Cloud Storage secondary bucket"
  type        = string
}

variable "source_project_id" {
  type = string
}

variable "target_project_id" {
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

variable "target_project_number" {
  description = "Project Number of the secondary region"
  type        = number
}
