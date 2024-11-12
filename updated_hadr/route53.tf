resource "aws_route53_zone" "private_zone" {
  count    = var.region == "us-west-1" ? 1 : 0
  name = var.private_zone_name
  vpc {
    vpc_id = var.primary_vpc_id
  }
  vpc {
    vpc_id = var.secondary_vpc_id
    vpc_region = "us-gov-east-1"
  }
}

resource "aws_route53_health_check" "primary_health_check" {
  count    = var.region == "us-west-1" ? 1 : 0
  fqdn              = aws_lb.network_lb.dns_name
  port              = 80
  type              = "HTTP"  # Change to HTTP if using HTTP health check
  resource_path     = "/"
  failure_threshold = 1
  request_interval  = 10
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

# Route 53 CNAME Web Record for the primary Load Balancer
resource "aws_route53_record" "primary_web_cname_record" {
  count    = var.region == "us-west-1" ? 1 : 0
  zone_id = aws_lb.network_lb.zone_id # Route 53 Hosted Zone ID
  name    = "web.${var.private_zone_name}"  
  type    = "CNAME"
  ttl     = 10
  records = [aws_lb.network_lb.dns_name]
  set_identifier = "Primary"
  failover_routing_policy {
    type = "PRIMARY"

  }
  health_check_id = aws_route53_health_check.health_check[count.index].id
}

# Route 53 CNAME Web Record for the secondary Load Balancer
resource "aws_route53_record" "secondary_web_cname_record" {
  count    = var.region == "us-east-1" ? 1 : 0
  zone_id = aws_lb.network_lb.zone_id # Route 53 Hosted Zone ID
  name    = "web.${var.private_zone_name}"  
  type    = "CNAME"
  ttl     = 10
  records = [aws_lb.network_lb.dns_name]
  set_identifier = "Secondary"
  failover_routing_policy {
    type = "SECONDARY"
  }
}

# Route 53 Alias Record to point to NLB
resource "aws_route53_record" "primary_alias_record" {
  count    = var.region == "us-west-1" ? 1 : 0
  zone_id = aws_route53_zone.private_zone[count.index].id
  name    = "app.${var.private_zone_name}" 
  type    = "A"
  alias {
    name                   = aws_lb.network_lb.dns_name
    zone_id                = aws_lb.network_lb.zone_id
    evaluate_target_health = true
  }
  set_identifier = "Primary"
  failover_routing_policy {
    type = "PRIMARY"
  }
  health_check_id = aws_route53_health_check.primary_health_check[count.index].id
}

data "aws_route53_zone" "private_zone_secondary" {
  count = var.region == "us-east-1" ? 1 : 0
  name  = var.private_zone_name
  private_zone = true
}

resource "aws_route53_record" "secondary_alias_record" {
  count    = var.region == "us-east-1" ? 1 : 0
  zone_id = data.aws_route53_zone.private_zone_secondary[0].id
  name    = "app.${var.private_zone_name}" 
  type    = "A"
  alias {
    name                   = aws_lb.network_lb.dns_name
    zone_id                = aws_lb.network_lb.zone_id
    evaluate_target_health = true
  }
  set_identifier = "Secondary"
  failover_routing_policy {
    type = "SECONDARY"
  }
}

