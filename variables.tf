variable "region" {
  type        = string
  description = "AWS region where resources will be created"
}

variable "bucket_name" {
  type        = string
  description = "S3 bucket name for Elastic Beanstalk application versions"
}

variable "eb_app_name" {
  type        = string
  description = "Name of the Elastic Beanstalk application"
}

variable "env_name" {
  type        = string
  description = "Name of the Elastic Beanstalk environment"
}

variable "instance_type" {
  type        = string
  description = "Instance type for Elastic Beanstalk environment"
}

variable "solution_stack" {
  type        = string
  description = "Elastic Beanstalk solution stack (platform)"
}

variable "private_dns_domain_name" {
  type        = string
  description = "Private DNS domain name for the hosted zone"
}

variable "vpc_id" {
  type        = string
  description = "The VPC ID where the Elastic Beanstalk environment will be deployed"
}

variable "subnet_ids" {
  type        = list(string)
  description = "List of subnet IDs where the Elastic Beanstalk environment will be deployed"
}

variable "security_group_ids" {
  type        = list(string)
  description = "List of security group IDs to attach to Elastic Beanstalk instances"
  default     = []
}

variable "private_dns_record" {
  type        = string
  description = "DNS record for the Elastic Beanstalk environment within the private hosted zone"
}

variable "health_check_enabled" {
  type        = bool
  description = "Whether to enable Route 53 health check for the Elastic Beanstalk environment"
  default     = false
}
