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

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "subnet_id" {
  description = "Subnet ID for the instance"
  type        = string
}

variable "lb_subnet_id" {
  description = "Subnet ID for the internal load balancer"
  type        = string
}

variable "lb_ip_address" {
  description = "IP Address for the internal load balancer"
  type        = string
}
