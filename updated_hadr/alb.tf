# Security Group for Load Balancer to allow HTTP access
resource "aws_security_group" "allow_lb_http" {
  name_prefix = "allow_lb_http"
  vpc_id = var.alb_vpc_id
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


# Load Balancer (CLB) with single Availability Zone in us-west-1
resource "aws_elb" "app_lb" {
  count    = var.region == "us-west-1" ? 1 : 0
  name               = "app-lb-${var.region}"
  internal           = false
  security_groups    = [aws_security_group.allow_lb_http.id]
  subnets            = var.alb_subnet_ids
  cross_zone_load_balancing = false  
  listener {
    lb_port           = 80
    instance_port     = 80
    protocol          = "HTTP"
  }

  health_check {
    target              = "HTTP:80/"
    interval            = 10
    timeout             = 5
    unhealthy_threshold = 2
    healthy_threshold   = 2
  }

  instances = [aws_instance.primary_instance.id]

  tags = {
    Name = "app-lb-${var.region}"
  }
}


# Load Balancer (CLB) with single Availability Zone in us-west-1
resource "aws_elb" "app_lb" {
  count    = var.region == "us-east-1" ? 1 : 0
  name               = "app-lb-${var.region}"
  internal           = false
  security_groups    = [aws_security_group.allow_lb_http.id]
  subnets            = var.alb_subnet_ids
  cross_zone_load_balancing = false  
  listener {
    lb_port           = 80
    instance_port     = 80
    protocol          = "HTTP"
  }

  health_check {
    target              = "HTTP:80/"
    interval            = 10
    timeout             = 5
    unhealthy_threshold = 2
    healthy_threshold   = 2
  }

  instances = [aws_instance.secondary_instance.id]

  tags = {
    Name = "app-lb-${var.region}"
  }
}
