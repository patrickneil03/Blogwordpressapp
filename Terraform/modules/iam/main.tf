data "aws_caller_identity" "current" {}

locals {
  base_path  = "/BLOG/Wordpress"
  region     = var.region
  account_id = data.aws_caller_identity.current.account_id

  ssm_params_arns = [
    "arn:aws:ssm:${local.region}:${local.account_id}:parameter${local.base_path}/DBPassword",
    "arn:aws:ssm:${local.region}:${local.account_id}:parameter${local.base_path}/DBRootPassword",
    "arn:aws:ssm:${local.region}:${local.account_id}:parameter${local.base_path}/DBUser",
    "arn:aws:ssm:${local.region}:${local.account_id}:parameter${local.base_path}/DBName",
    "arn:aws:ssm:${local.region}:${local.account_id}:parameter${local.base_path}/DBEndpoint",
    "arn:aws:ssm:${local.region}:${local.account_id}:parameter${local.base_path}/EFSFileSystemID",
    "arn:aws:ssm:${local.region}:${local.account_id}:parameter${local.base_path}/ALBDNSName"
  ]

  kms_key_arn = length(trimspace(var.kms_key_id)) > 0 ? var.kms_key_id : "arn:aws:kms:${var.region}:${data.aws_caller_identity.current.account_id}:alias/aws/ssm"
}

####################################################
############## IAM ROLE ############################
####################################################

resource "aws_iam_role" "ec2_blog_role" {
  name = "BlogEC2Role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = { Service = "ec2.amazonaws.com" }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name    = "BlogEC2Role"
    Project = "BLOG"
  }
}

####################################################
############## CUSTOM IAM POLICY ###################
####################################################

resource "aws_iam_policy" "ec2_blog_policy" {
  name        = "EC2Blog-Policy"
  description = "Allow EC2 to access ECR, SSM, EFS, and CloudWatch"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      # ECR Permissions
      {
        Sid    = "ECRGetAuthToken"
        Effect = "Allow"
        Action = ["ecr:GetAuthorizationToken"]
        Resource = "*"
      },
      {
        Sid    = "ECRPullImages"
        Effect = "Allow"
        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:DescribeImages"
        ]
        Resource = var.ecr_repo_arn
      },
      # SSM Parameter Store Permissions
      {
        Sid    = "SSMReadParameters"
        Effect = "Allow"
        Action = [
          "ssm:GetParameter",
          "ssm:GetParameters"
        ]
        Resource = local.ssm_params_arns
      },
      # KMS for SSM parameter decryption
      {
        Sid    = "KMSDecryptSSM"
        Effect = "Allow"
        Action = ["kms:Decrypt"]
        Resource = [local.kms_key_arn]
      },
      # EFS Permissions (minimal required)
      {
        Sid    = "EFSMount"
        Effect = "Allow"
        Action = [
          "elasticfilesystem:DescribeFileSystems",
          "elasticfilesystem:DescribeMountTargets"
        ]
        Resource = "*"
      },
      # CloudWatch Logs (for logging)
      {
        Sid    = "CloudWatchLogs"
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams"
        ]
        Resource = "arn:aws:logs:${local.region}:${local.account_id}:log-group:/aws/ec2/wordpress*"
      },
      # CloudWatch Metrics
      {
        Sid    = "CloudWatchMetrics"
        Effect = "Allow"
        Action = [
          "cloudwatch:PutMetricData"
        ]
        Resource = "*"
      }
    ]
  })
}

####################################################
############## ATTACH POLICIES #####################
####################################################

# Attach custom policy
resource "aws_iam_role_policy_attachment" "attach_custom_policy" {
  role       = aws_iam_role.ec2_blog_role.name
  policy_arn = aws_iam_policy.ec2_blog_policy.arn
}

# Optional: Only if you need SSM Session Manager access
resource "aws_iam_role_policy_attachment" "ssm_core" {
role       = aws_iam_role.ec2_blog_role.name
policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

####################################################
############## INSTANCE PROFILE ####################
####################################################

resource "aws_iam_instance_profile" "ec2_blog_profile" {
  name = "BlogEC2InstanceProfile"
  role = aws_iam_role.ec2_blog_role.name

  tags = {
    Name    = "BlogEC2InstanceProfile"
    Project = "BLOG"
  }
}