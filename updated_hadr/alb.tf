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

resource "aws_lb" "network_lb" {
  name               = "app-network-lb"
  internal           = false
  load_balancer_type = "network"
  security_groups    = [aws_security_group.allow_http.id]
  subnets            = var.alb_subnet_ids
}

resource "aws_lb_target_group" "nlb_target_group" {
  name        = "my-target-group"
  port        = 80
  protocol    = "TCP"
  target_type = "ip" 
  vpc_id      = var.alb_vpc_id

  health_check {
    interval            = 10
    path                = "/"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

resource "aws_lb_listener" "nlb_listener" {
  load_balancer_arn = aws_lb.network_lb.arn
  port              = 80
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.nlb_target_group.arn
  }
}

resource "aws_lb_target_group_attachment" "ip_target_attachment" {
  target_group_arn = aws_lb_target_group.nlb_target_group.arn
  target_id        = var.private_ip
  port             = 80
}
