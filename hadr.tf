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
