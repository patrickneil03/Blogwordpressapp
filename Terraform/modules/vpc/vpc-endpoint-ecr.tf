####################################################
######### VPC ENDPOINTS FOR ECR ACCESS #############
####################################################

# Local variable to get App subnet IDs (updated for 2 AZs)
locals {
  app_subnet_ids = [
    aws_subnet.named["App-subnet-A"].id,
    aws_subnet.named["App-subnet-B"].id
  ]
}

# 1. ECR API Endpoint (Interface)
resource "aws_vpc_endpoint" "ecr_api" {
  vpc_id              = aws_vpc.blog_vpc.id
  service_name        = "com.amazonaws.${var.region}.ecr.api"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  
  subnet_ids         = local.app_subnet_ids
  security_group_ids = [var.vpc_endpoint_sg_id]

  tags = merge(local.tags, { Name = "ecr-api-endpoint" })
}

# 2. ECR Docker Endpoint (Interface)
resource "aws_vpc_endpoint" "ecr_dkr" {
  vpc_id              = aws_vpc.blog_vpc.id
  service_name        = "com.amazonaws.${var.region}.ecr.dkr"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  
  subnet_ids         = local.app_subnet_ids
  security_group_ids = [var.vpc_endpoint_sg_id]

  tags = merge(local.tags, { Name = "ecr-dkr-endpoint" })
}

# 3. S3 Gateway Endpoint (Gateway - FREE!)
# Update: Use BOTH App route tables since App instances need S3 access
resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.blog_vpc.id
  service_name      = "com.amazonaws.${var.region}.s3"
  vpc_endpoint_type = "Gateway"
  
  # Add routes to both App route tables
  route_table_ids = [
    aws_route_table.app_with_nat_az1.id,
    aws_route_table.app_with_nat_az2.id
  ]

  tags = merge(local.tags, { Name = "s3-gateway-endpoint" })
}

# 4. SSM Endpoint (Interface - for Parameter Store)
resource "aws_vpc_endpoint" "ssm" {
  vpc_id              = aws_vpc.blog_vpc.id
  service_name        = "com.amazonaws.${var.region}.ssm"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  
  subnet_ids         = local.app_subnet_ids
  security_group_ids = [var.vpc_endpoint_sg_id]

  tags = merge(local.tags, { Name = "ssm-endpoint" })
}

# 5. SSMMessages Endpoint (REQUIRED for Session Manager)
resource "aws_vpc_endpoint" "ssmmessages" {
  vpc_id              = aws_vpc.blog_vpc.id
  service_name        = "com.amazonaws.${var.region}.ssmmessages"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  
  subnet_ids         = local.app_subnet_ids
  security_group_ids = [var.vpc_endpoint_sg_id]

  tags = merge(local.tags, { Name = "ssmmessages-endpoint" })
}

# 6. EC2Messages Endpoint (REQUIRED for Session Manager)
resource "aws_vpc_endpoint" "ec2messages" {
  vpc_id              = aws_vpc.blog_vpc.id
  service_name        = "com.amazonaws.${var.region}.ec2messages"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  
  subnet_ids         = local.app_subnet_ids
  security_group_ids = [var.vpc_endpoint_sg_id]

  tags = merge(local.tags, { Name = "ec2messages-endpoint" })
}

# 7. Logs Endpoint (Optional but recommended for CloudWatch)
resource "aws_vpc_endpoint" "logs" {
  vpc_id              = aws_vpc.blog_vpc.id
  service_name        = "com.amazonaws.${var.region}.logs"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  
  subnet_ids         = local.app_subnet_ids
  security_group_ids = [var.vpc_endpoint_sg_id]

  tags = merge(local.tags, { Name = "logs-endpoint" })
}