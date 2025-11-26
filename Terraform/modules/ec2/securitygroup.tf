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
    cidr_blocks = ["180.190.225.149/32"]
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
#############RDS SECURITY GROUP#####################
####################################################


resource "aws_security_group" "rds" {
  name        = "rds-sg"
  description = "Allow DB access only from web servers"
  vpc_id      = var.vpc_id

  # Allow inbound from web servers on MySQL/MariaDB port
  ingress {
    description      = "Allow web servers to connect to RDS Instance"
    from_port        = 3306
    to_port          = 3306
    protocol         = "tcp"
    security_groups  = [aws_security_group.goingtointernet.id]
  }

  # Optional: if you use a different DB engine, adjust the port accordingly
  # e.g., PostgreSQL 5432

  # Egress: allow outbound for updates/replication
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

}


####################################################
#############EFS SECURITY GROUP#####################
####################################################
resource "aws_security_group" "efs" {
  name        = "efs-sg"
  description = "Allow NFS access only from web servers"
  vpc_id      = var.vpc_id

  # Allow inbound from web servers on NFS port
  ingress {
    description      = "Allow web servers to connect to EFS"
    from_port        = 2049
    to_port          = 2049
    protocol         = "tcp"
    security_groups  = [aws_security_group.goingtointernet.id]
  }

  # Egress: allow outbound for updates/replication
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