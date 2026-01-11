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
    description = "Allow inbound SSH from my wifi"
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
  
  # ✅ EXACTLY YOUR USER DATA
  user_data = <<-EOF
              #!/bin/bash
              # Install ONLY Docker and EFS packages
              sudo yum install -y docker     
              sudo yum install -y amazon-efs-utils
              sudo systemctl enable docker
              sudo systemctl start docker
              
              # Auto-shutdown after 10 minutes (safety net)
              echo "shutdown -h +10" | at now
              
              # Clean up
              sudo yum clean all
              
              # Create completion marker
              echo "AMI_BUILD_COMPLETE=$(date)" > /tmp/ami-build-status.txt
              docker --version >> /tmp/ami-build-status.txt
              
              echo "AMI build completed at $(date)"
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
  
   lifecycle {
    ignore_changes = [
      associate_public_ip_address,  # AWS may release IP when stopped
      security_groups,              # AWS manages this
      tags_all,                     # Ignore AWS-added tags
    ]
  }
}

# Create AMI
resource "aws_ami_from_instance" "wordpress_ami" {
  name               = "wordpress-docker-efs-v${var.ami_version}"
  description        = "AMI with Docker and EFS pre-installed"
  source_instance_id = aws_instance.ami_builder.id
  
  snapshot_without_reboot = true
  
  tags = {
    Name     = "wordpress-docker-efs"
    Version  = var.ami_version
    Packages = "docker, efs-utils"
    
  }

}


