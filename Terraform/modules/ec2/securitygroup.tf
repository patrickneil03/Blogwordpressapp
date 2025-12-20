
resource "aws_security_group" "goingtointernet" {
  name        = "goingtointernet"
  description = "Allow outbound HTTP and ICMP to the internet"
  vpc_id      = var.vpc_id

  # Allow inbound HTTP (TCP 80) to anywhere
  ingress {
    description = "Allow Inbound HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

   # Allow inbound HTTPS (TCP 443) to anywhere
  ingress {
    description = "Allow Inbound HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow inbound ICMP (all types/codes) to anywhere
  ingress {
    description = "Allow inbound ICMP from my wifi"
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["180.190.225.149/32"]
  }

    # Allow inbound SSH (TCP 22) from anywhere
  ingress {
    description = "Allow inbound SSH from my wifi"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Default egress (allow all outbound)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

}


####################################################
#############LOAD BALANCER SECURITY GROUP###########
####################################################

resource "aws_security_group" "load_balancer" {
  name        = "load-balancer-sg"
  description = "Allow inbound HTTP/HTTPS from anywhere"
  vpc_id      = var.vpc_id

  # Allow inbound HTTP (TCP 80) from anywhere
  ingress {
    description = "Allow inbound HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow inbound HTTPS (TCP 443) from anywhere
  ingress {
    description = "Allow inbound HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "load-balancer-sg"
  }
}

####################################################
#############APP SECURITY GROUP#####################
####################################################

resource "aws_security_group" "app" {
  name        = "wordpress-app-sg"
  description = "Security group for WordPress EC2 instances"
  vpc_id      = var.vpc_id

  # Allow HTTP from ALB
  ingress {
    description     = "Allow HTTP from ALB"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.load_balancer.id]
  }

  # Allow all outbound (including to EFS, RDS, VPC endpoints)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "wordpress-app-sg"
  }
}

####################################################
#############EFS SECURITY GROUP#####################
####################################################

resource "aws_security_group" "efs" {
  name        = "efs-sg"
  description = "Allow NFS access only from app instances"
  vpc_id      = var.vpc_id

  # Allow inbound from app instances on NFS port
  ingress {
    description     = "Allow NFS from app instances"
    from_port       = 2049
    to_port         = 2049
    protocol        = "tcp"
    security_groups = [aws_security_group.app.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "efs-sg"
  }
}

####################################################
#############RDS SECURITY GROUP#####################
####################################################

resource "aws_security_group" "rds" {
  name        = "rds-sg"
  description = "Allow DB access only from app instances"
  vpc_id      = var.vpc_id

  # Allow inbound from app instances on MySQL/MariaDB port
  ingress {
    description     = "Allow MySQL from app instances"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.app.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "rds-sg"
  }
}

####################################################
#############VPC ENDPOINT SECURITY GROUP############
####################################################

resource "aws_security_group" "vpc_endpoint" {
  name        = "vpc-endpoint-sg"
  description = "Security group for VPC endpoints (ECR, SSM)"
  vpc_id      = var.vpc_id

  # Allow HTTPS from app instances
  ingress {
    description = "Allow HTTPS from VPC CIDR"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    security_groups = [aws_security_group.app.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    security_groups = [aws_security_group.app.id]
  }

  tags = {
    Name = "vpc-endpoint-sg"
  }
}