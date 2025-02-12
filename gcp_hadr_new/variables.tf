variable "region" {
  description = "GCP region"
  type        = string
}

variable "us_west_bucket_name" {
  description = "Name of the Cloud Storage primary bucket"
  type        = string
}

variable "us_east_bucket_name" {
  description = "Name of the Cloud Storage secondary bucket"
  type        = string
}

variable "us_west_project_id" {
  type = string
}

variable "us_east_project_id" {
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

variable "us_east_project_number" {
  description = "Project Number of the secondary region"
  type        = number
}

variable "db_instance_name" {
  description = "The name of the DB instance"
  type        = string
}

variable "db_name" {
  description = "The name of the Database"
  type        = string
}



variable "vpc_id" {
  description = "Host network vpc_id"
  type        = string
}

variable "us_west_subnet_id" {
  description = "US West subnet id"
  type        = string
}

variable "us_east_subnet_id" {
  description = "US East subnet id"
  type        = string
}

variable "host_project_id" {
  description = "Host Project ID"
  type        = string
}
