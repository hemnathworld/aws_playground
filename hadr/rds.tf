
# Primary RDS Database Instance
resource "aws_db_instance" "primary" {
  count       = var.region == "us-west-1" ? 1 : 0
  identifier              = var.db_identifier
  engine                 = "mysql"  # Change this to your preferred DB engine
  instance_class         = "db.t3.micro"
  allocated_storage       = 20
  username               = var.db_username
  password               = var.db_password
  db_subnet_group_name   = aws_db_subnet_group.primary[count.index].id
  vpc_security_group_ids = [aws_security_group.primary[count.index].id]
  
  backup_retention_period = 7 
  # Multi-AZ for failover capability
  multi_az               = true

  tags = {
    Name = "${var.db_identifier}-primary"
  }
}

# Subnet Group for Primary RDS
resource "aws_db_subnet_group" "primary" {
  count       = var.region == "us-west-1" ? 1 : 0
  name       = "${var.db_identifier}-primary"
  subnet_ids = var.db_subnet_ids  # Provide your subnet IDs

  tags = {
    Name = "${var.db_identifier}-primary-subnet-group"
  }
}

# Security Group for Primary RDS
resource "aws_security_group" "primary" {
  count       = var.region == "us-west-1" ? 1 : 0
  name        = "${var.db_identifier}-primary-sg"
  description = "Allow access to primary RDS"

  ingress {
    from_port   = 3306  # Change this if using a different DB engine
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Adjust as needed
  }
}

# RDS Read Replica
resource "aws_db_instance" "replica" {
  count       = var.region == "us-east-1" ? 1 : 0
  identifier            = "${var.db_identifier}-replica"
  engine                = "mysql" 
  instance_class        = "db.t3.micro"
  db_subnet_group_name  = aws_db_subnet_group.replica[count.index].id
  vpc_security_group_ids = [aws_security_group.replica[count.index].id]
  backup_retention_period = 7 
  # Reference the primary instance
  replicate_source_db   = "arn:aws:rds:us-west-1:${data.aws_caller_identity.current.account_id}:db:${var.db_identifier}"
  
  tags = {
    Name = "${var.db_identifier}-replica"
  }
}

# Subnet Group for Replica RDS
resource "aws_db_subnet_group" "replica" {
  count       = var.region == "us-east-1" ? 1 : 0
  name      = "${var.db_identifier}-replica"
  subnet_ids = var.db_subnet_ids  # Provide your subnet IDs

  tags = {
    Name = "${var.db_identifier}-replica-subnet-group"
  }
}

# Security Group for Replica RDS
resource "aws_security_group" "replica" {
  count       = var.region == "us-east-1" ? 1 : 0
  name        = "${var.db_identifier}-replica-sg"
  description = "Allow access to replica RDS"

  ingress {
    from_port   = 3306  # Change this if using a different DB engine
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Adjust as needed
  }
}
