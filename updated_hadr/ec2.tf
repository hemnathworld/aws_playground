locals {
  user_data_files = {
    "us-west-1" = "scripts/us-west-1_user_data.sh"
    "us-east-1" = "scripts/us-east-1_user_data.sh"
    # Add more regions as needed
  }

  user_data_file = lookup(local.user_data_files, var.region)
}

resource "aws_security_group" "allow_http_primary" {
  count    = var.region == "us-west-1" ? 1 : 0
  name_prefix = "allow_http"
  vpc_id = var.primary_vpc_id
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 5000
    to_port     = 5000
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

resource "aws_security_group" "allow_http_secondary" {
  count    = var.region == "us-east-1" ? 1 : 0
  name_prefix = "allow_http"
  vpc_id = var.secondary_vpc_id
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 5000
    to_port     = 5000
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

resource "aws_instance" "app_server_primary" {
  count    = var.region == "us-west-1" ? 1 : 0
  ami                    = var.ami
 instance_type          = "t2.micro"
  iam_instance_profile   = var.iam_profile_name
  vpc_security_group_ids = [aws_security_group.allow_http_primary[count.index].id]
  subnet_id              = var.subnet_id
  private_ip             = var.private_ip

  user_data = <<-EOF
    #!/bin/bash
    ${file(local.user_data_file)}
  EOF

  tags = {
    Name = "AppServer"
  }
}

resource "aws_instance" "app_server" {
  count    = var.region == "us-east-1" ? 1 : 0
  ami                    = var.ami
 instance_type          = "t2.micro"
  iam_instance_profile   = var.iam_profile_name
  vpc_security_group_ids = [aws_security_group.allow_http_secondary[count.index].id]
  subnet_id              = var.subnet_id
  private_ip             = var.private_ip

  user_data = <<-EOF
    #!/bin/bash
    ${file(local.user_data_file)}
  EOF

  tags = {
    Name = "AppServer"
  }
}


# Security Group for Load Balancer to allow HTTP access
resource "aws_security_group" "allow_lb_http" {
  name_prefix = "allow_lb_http"
  vpc_id = alb_vpc_id
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

# Load Balancer for each region
resource "aws_lb" "app_lb" {
  name               = "app-lb-${var.region}"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.allow_lb_http.id]
  subnets            = var.alb_subnet_ids

  tags = {
    Name = "AppLoadBalancer-${var.region}"
  }
}

# Target Group for EC2 instance backend, using private IP
resource "aws_lb_target_group" "app_target_group" {
  name        = "app-tg-${var.region}"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"  

  health_check {
    path                = "/"
    protocol            = "HTTP"
    interval            = 10
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

# Register EC2 instance with Target Group using its private IP
resource "aws_lb_target_group_attachment" "app_attachment" {
  target_group_arn = aws_lb_target_group.app_target_group.arn
  target_id        = var.private_ip
  port             = 80
}

# Load Balancer Listener to forward traffic to the Target Group
resource "aws_lb_listener" "app_listener" {
  load_balancer_arn = aws_lb.app_lb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_target_group.arn
  }
}
