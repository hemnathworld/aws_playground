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

variable "existing_private_zone_id" {
  type        = string
  description = "ID of an existing Route 53 private hosted zone for the environment"
  default     = ""
}

variable "private_dns_domain_name" {
  type        = string
  description = "Private DNS domain name for the hosted zone"
}

variable "vpc_id" {
  type        = string
  description = "The VPC ID where the private DNS hosted zone will be associated"
}

variable "private_dns_record" {
  type        = string
  description = "DNS record for the Elastic Beanstalk environment within the private hosted zone"
}

variable "zone_id" {
  type        = string
  description = "The zone ID for aliasing Route 53 records"
}

variable "health_check_enabled" {
  type        = bool
  description = "Whether to enable Route 53 health check for the Elastic Beanstalk environment"
  default     = false
}





# AWS provider for the given region
provider "aws" {
  region = var.region
}

# Conditional creation of Private DNS Hosted Zone (only in us-west-1)
resource "aws_route53_zone" "private_dns_zone" {
  count       = var.region == "us-west-1" ? 1 : 0
  name        = var.private_dns_domain_name
  vpc {
    vpc_id = var.vpc_id
  }
  comment     = "Private hosted zone for internal DNS"
  private_zone = true
}

# Elastic Beanstalk Application
resource "aws_elastic_beanstalk_application" "app" {
  name        = var.eb_app_name
  description = "Elastic Beanstalk application"
}

# Elastic Beanstalk environment
resource "aws_elastic_beanstalk_environment" "env" {
  name                = var.env_name
  application         = aws_elastic_beanstalk_application.app.name
  solution_stack_name = var.solution_stack

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "InstanceType"
    value     = var.instance_type
  }
}

# Route 53 DNS record for the environment (Private DNS)
resource "aws_route53_record" "eb_private_dns" {
  zone_id = coalesce(aws_route53_zone.private_dns_zone[0].id, var.existing_private_zone_id)
  name    = var.private_dns_record
  type    = "A"

  alias {
    name                   = aws_elastic_beanstalk_environment.env.endpoint_url
    zone_id                = var.zone_id
    evaluate_target_health = var.health_check_enabled
  }
}

# Optional Route 53 health check if enabled
resource "aws_route53_health_check" "eb_health_check" {
  count              = var.health_check_enabled ? 1 : 0
  fqdn               = aws_elastic_beanstalk_environment.env.endpoint_url
  type               = "HTTPS"
  resource_path      = "/"
  request_interval   = 30
  failure_threshold  = 3
}
