locals {
  user_data_files = {
    "us-west-1" = "scripts/us-west-1_user_data.sh"
    "us-east-1" = "scripts/us-east-1_user_data.sh"
    # Add more regions as needed
  }

  user_data_file = lookup(local.user_data_files, var.region)
}

resource "aws_security_group" "allow_http" {
  name_prefix = "allow_http"

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

resource "aws_instance" "app_server" {
  ami                    = var.ami
 instance_type          = "t2.micro"
  iam_instance_profile   = "ec2_instance_profile"
  vpc_security_group_ids = [aws_security_group.allow_http.id]
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
