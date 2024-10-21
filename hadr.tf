provider "aws" {
  alias = "primary"
  region = "us-west-1"
}

provider "aws" {
  alias = "failover"
  region = "us-east-1"
}


# Create Elastic Beanstalk Application
resource "aws_elastic_beanstalk_application" "app" {
  provider = aws.primary
  name     = "my-elastic-beanstalk-app"
}

resource "aws_elastic_beanstalk_application" "app_failover" {
  provider = aws.failover
  name     = "my-elastic-beanstalk-app"
}

# Primary Elastic Beanstalk environment in us-west-1
resource "aws_elastic_beanstalk_environment" "primary_env" {
  provider        = aws.primary
  name            = "my-primary-env"
  application     = aws_elastic_beanstalk_application.app.name
  solution_stack_name = "64bit Amazon Linux 2 v3.3.4 running Node.js 14"
  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "InstanceType"
    value     = "t2.micro"
  }
}

# Failover Elastic Beanstalk environment in us-east-1
resource "aws_elastic_beanstalk_environment" "failover_env" {
  provider        = aws.failover
  name            = "my-failover-env"
  application     = aws_elastic_beanstalk_application.app_failover.name
  solution_stack_name = "64bit Amazon Linux 2 v3.3.4 running Node.js 14"
  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "InstanceType"
    value     = "t2.micro"
  }
}

# Create Route 53 health checks for both environments
resource "aws_route53_health_check" "primary_health_check" {
  fqdn              = aws_elastic_beanstalk_environment.primary_env.endpoint_url
  type              = "HTTPS"
  resource_path     = "/"
  request_interval  = 30
  failure_threshold = 3
}

resource "aws_route53_health_check" "failover_health_check" {
  fqdn              = aws_elastic_beanstalk_environment.failover_env.endpoint_url
  type              = "HTTPS"
  resource_path     = "/"
  request_interval  = 30
  failure_threshold = 3
}

# Create Route 53 failover DNS records
resource "aws_route53_record" "primary" {
  zone_id = "YOUR_ZONE_ID"
  name    = "myapp.example.com"
  type    = "A"
  set_identifier = "Primary Region"
  alias {
    name                   = aws_elastic_beanstalk_environment.primary_env.endpoint_url
    zone_id                = "YOUR_PRIMARY_BEANSTALK_ZONE_ID"
    evaluate_target_health = true
  }
  failover_routing_policy {
    type = "PRIMARY"
  }
  health_check_id = aws_route53_health_check.primary_health_check.id
}

resource "aws_route53_record" "failover" {
  zone_id = "YOUR_ZONE_ID"
  name    = "myapp.example.com"
  type    = "A"
  set_identifier = "Failover Region"
  alias {
    name                   = aws_elastic_beanstalk_environment.failover_env.endpoint_url
    zone_id                = "YOUR_FAILOVER_BEANSTALK_ZONE_ID"
    evaluate_target_health = true
  }
  failover_routing_policy {
    type = "SECONDARY"
  }
  health_check_id = aws_route53_health_check.failover_health_check.id
}
