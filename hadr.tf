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

# Lookup zone ID for us-east-1 using the domain name
data "aws_route53_zone" "private_zone" {
  count       = var.region == "us-east-1" ? 1 : 0
  name        = var.private_dns_domain_name
  private_zone = true
}

# Elastic Beanstalk Application
resource "aws_elastic_beanstalk_application" "app" {
  name        = var.eb_app_name
  description = "Elastic Beanstalk application"
}

# Elastic Beanstalk environment within VPC
resource "aws_elastic_beanstalk_environment" "env" {
  name                = var.env_name
  application         = aws_elastic_beanstalk_application.app.name
  solution_stack_name = var.solution_stack

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "InstanceType"
    value     = var.instance_type
  }

  setting {
    namespace = "aws:ec2:vpc"
    name      = "VPCId"
    value     = var.vpc_id
  }

  setting {
    namespace = "aws:ec2:vpc"
    name      = "Subnets"
    value     = join(",", var.subnet_ids)
  }

  # Optionally specify security groups
  setting {
    namespace = "aws:ec2:vpc"
    name      = "SecurityGroups"
    value     = join(",", var.security_group_ids)
  }
}

# DNS Alias Record for Elastic Beanstalk Private Endpoint
resource "aws_route53_record" "eb_private_dns" {
  zone_id = var.region == "us-west-1" ? aws_route53_zone.private_dns_zone[0].id : data.aws_route53_zone.private_zone[0].zone_id
  name    = var.private_dns_record
  type    = "CNAME"
  ttl     = 60

  records = [aws_elastic_beanstalk_environment.env.cname]
}

# Optional Route 53 health check if enabled
resource "aws_route53_health_check" "eb_health_check" {
  count              = var.health_check_enabled ? 1 : 0
  fqdn               = aws_elastic_beanstalk_environment.env.cname
  type               = "HTTPS"
  resource_path      = "/"
  request_interval   = 30
  failure_threshold  = 3
}
