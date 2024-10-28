resource "aws_cloudwatch_metric_alarm" "instance_status_check" {
  count    = var.region == "us-west-1" ? 1 : 0
  alarm_name          = "PrimaryInstanceStatusCheck"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "1"
  metric_name        = "StatusCheckFailed"
  namespace          = "AWS/EC2"
  period             = "60"
  statistic          = "Average"
  threshold          = "1"
  alarm_description  = "Alarm when the primary instance fails status checks"  
  dimensions = {
    InstanceId = aws_instance.app_server_primary.id 
  }
 }

resource "aws_route53_health_check" "health_check" {
  count    = var.region == "us-west-1" ? 1 : 0
  type                            = "CLOUDWATCH_METRIC"
  cloudwatch_alarm_name           = aws_cloudwatch_metric_alarm.instance_status_check[count.index].alarm_name
  cloudwatch_alarm_region         = var.region
  insufficient_data_health_status = "Healthy"
}

resource "aws_route53_zone" "private_zone" {
  count    = var.region == "us-west-1" ? 1 : 0
  name = var.private_zone_name
  vpc {
    vpc_id = var.primary_vpc_id
  }
  vpc {
    vpc_id = var.secondary_vpc_id
  }
}

resource "aws_vpc_dhcp_options" "dhcp_options" {
  domain_name          = var.private_zone_name
  domain_name_servers  = ["AmazonProvidedDNS"]  
}

resource "aws_vpc_dhcp_options_association" "dhcp_options_association_primary" {
  count    = var.region == "us-west-1" ? 1 : 0
  vpc_id          = var.primary_vpc_id
  dhcp_options_id = aws_vpc_dhcp_options.dhcp_options.id
}

resource "aws_vpc_dhcp_options_association" "dhcp_options_association_secondary" {
  count    = var.region == "us-east-1" ? 1 : 0
  vpc_id          = var.secondary_vpc_id
  dhcp_options_id = aws_vpc_dhcp_options.dhcp_options.id
}

resource "aws_route53_record" "failover_primary" {
  count    = var.region == "us-west-1" ? 1 : 0
  zone_id = aws_route53_zone.private_zone[count.index].id
  name     = "app.${var.private_zone_name}"
  type     = "A"
  ttl      = 60
  records  = [var.private_ip]
  set_identifier = "Primary"
  failover_routing_policy {
    type = "PRIMARY"
   
  }
  health_check_id = aws_route53_health_check.health_check[count.index].id
}

data "aws_route53_zone" "private_zone_secondary" {
  count = var.region == "us-east-1" ? 1 : 0
  name  = var.private_zone_name
  private_zone = true
}

resource "aws_route53_record" "failover_secondary" {
  count    = var.region == "us-east-1" ? 1 : 0
  zone_id =  data.aws_route53_zone.private_zone_secondary[0].id
  name     = "app.${var.private_zone_name}"
  type     = "A"
  ttl      = 60
  records  = [var.private_ip]
  set_identifier = "Secondary"
  failover_routing_policy {
    type = "SECONDARY"
  }
}

