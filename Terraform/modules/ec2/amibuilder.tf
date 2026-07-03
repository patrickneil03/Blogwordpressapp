
# Get latest AL2023 AMI
data "aws_ssm_parameter" "al2023_latest" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}

# Use default VPC
data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# Minimal security group
resource "aws_security_group" "ami_builder" {
  name        = "ami-builder-sg"
  description = "AMI builder security group"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "Allow inbound SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow all outbound
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name    = "ami-builder-sg"
    Purpose = "temporary"
  }
}

# Create EC2 instance
# Create EC2 instance
resource "aws_instance" "ami_builder" {
  ami           = data.aws_ssm_parameter.al2023_latest.value
  instance_type = "t2.micro"

  subnet_id                   = data.aws_subnets.default.ids[0]
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.ami_builder.id]

  # ✅ KEY ADDITION: Terminate instead of Stop on shutdown
  instance_initiated_shutdown_behavior = "terminate"
  disable_api_termination              = false

  user_data = <<-EOF
              #!/bin/bash
              set -xe
              
              # Standard updates and installs
              sudo dnf update -y
              sudo dnf install -y docker amazon-efs-utils aws-cli
              
              sudo systemctl enable docker
              sudo systemctl start docker
              
              # Clean up to keep the AMI small
              sudo dnf clean all
              sudo rm -rf /var/cache/dnf
              
              # Sync filesystem to ensure all changes are written
              sync

              # ✅ Wait a moment for the AWS AMI process to have a clean starting point
              echo "Build complete. Shutting down to trigger auto-termination..."
              sleep 60 
              sudo shutdown -h now
              EOF

  tags = {
    Name = "ami-builder-source"
  }
}

# ✅ SIMPLEST FIX: Wait for instance to stop
resource "null_resource" "wait_for_shutdown" {
  depends_on = [aws_instance.ami_builder]

  provisioner "local-exec" {
    command = <<-EOT
      echo "Waiting for instance to shutdown (max 5 minutes)..."
      sleep 300  # Wait 5 minutes for user data to complete and shutdown
    EOT
  }
}

# Create AMI
resource "aws_ami_from_instance" "wordpress_ami" {
  name               = "wordpress-docker-efs-v${var.ami_version}"
  description        = "AMI with Docker, EFS utils, and AWS CLI pre-installed"
  source_instance_id = aws_instance.ami_builder.id

  # ✅ CRITICAL: Set to false to ensure clean state
  snapshot_without_reboot = false

  # ✅ SIMPLEST FIX: Wait for shutdown before creating AMI
  depends_on = [null_resource.wait_for_shutdown]

  tags = {
    Name     = "wordpress-docker-efs"
    Version  = var.ami_version
    Packages = "docker,amazon-efs-utils,aws-cli"
    Date     = timestamp()
  }
}