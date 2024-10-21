# Read config from JSON file
variable "config" {
  type = object({
    region               = string
    bucket_name          = string
    eb_app_name          = string
    env_name             = string
    instance_type        = string
    solution_stack       = string
    route53_zone_id      = string
    domain_name          = string
    zone_id              = string
    health_check_enabled = bool
  })
}

# AWS provider for the given region
provider "aws" {
  region = var.config.region
}

# S3 bucket for Elastic Beanstalk app versions
resource "aws_s3_bucket" "eb_application_bucket" {
  bucket = var.config.bucket_name
}

# Elastic Beanstalk Application
resource "aws_elastic_beanstalk_application" "app" {
  name        = var.config.eb_app_name
  description = "Elastic Beanstalk application"
}

# Elastic Beanstalk environment
resource "aws_elastic_beanstalk_environment" "env" {
  name                = var.config.env_name
  application         = aws_elastic_beanstalk_application.app.name
  solution_stack_name = var.config.solution_stack

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "InstanceType"
    value     = var.config.instance_type
  }
}

# Route 53 DNS record for the environment
resource "aws_route53_record" "eb_dns" {
  zone_id = var.config.route53_zone_id
  name    = var.config.domain_name
  type    = "A"

  alias {
    name                   = aws_elastic_beanstalk_environment.env.endpoint_url
    zone_id                = var.config.zone_id
    evaluate_target_health = var.config.health_check_enabled
  }
}

# (Optional) Route 53 health check if enabled
resource "aws_route53_health_check" "eb_health_check" {
  count              = var.config.health_check_enabled ? 1 : 0
  fqdn               = aws_elastic_beanstalk_environment.env.endpoint_url
  type               = "HTTPS"
  resource_path      = "/"
  request_interval   = 30
  failure_threshold  = 3
}
