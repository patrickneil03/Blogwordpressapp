
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
resource "aws_instance" "ami_builder" {
  ami           = data.aws_ssm_parameter.al2023_latest.value
  instance_type = "t2.micro"
  
  subnet_id              = data.aws_subnets.default.ids[0]
  associate_public_ip_address = true
  
  vpc_security_group_ids = [aws_security_group.ami_builder.id]
  
  # Allow termination
  disable_api_termination = false
  
  # ✅ IMPROVED: Add at command to ensure shutdown
  user_data = <<-EOF
              #!/bin/bash
              set -xe
              echo "Starting AMI build at $(date)"
              
              # Install packages using DNF
              sudo dnf update -y
              sudo dnf install -y docker amazon-efs-utils aws-cli
              
              # Enable and start Docker
              sudo systemctl enable docker
              sudo systemctl start docker
              
              # Verify installations
              docker --version && echo "✓ Docker installed"
              which mount.efs && echo "✓ EFS utils installed"
              aws --version && echo "✓ AWS CLI installed"
              
              # Clean up
              sudo dnf clean all
              
              # Create completion marker
              echo "AMI_BUILD_COMPLETE=$(date)" > /tmp/ami-build-status.txt
              echo "Packages: docker, amazon-efs-utils, aws-cli" >> /tmp/ami-build-status.txt
              
              echo "AMI build completed at $(date)"
              
              # ✅ CRITICAL: Force wait and shutdown
              sleep 120  # Wait 2 minutes to ensure everything is settled
              echo "Shutting down for AMI creation..."
              sudo shutdown -h now
              EOF
  
  # Root volume
  root_block_device {
    volume_size = 8
    volume_type = "gp3"
    delete_on_termination = true
  }
  
  tags = {
    Name        = "ami-builder"
    Purpose     = "ami-creation"
    AutoDestroy = "true"
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