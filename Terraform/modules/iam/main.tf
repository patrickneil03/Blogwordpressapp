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
    Project = "BLOG"
  }
}

resource "aws_iam_role_policy_attachment" "efs_attach" {
  role       = aws_iam_role.ec2_blog_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonElasticFileSystemClientFullAccess"
}

resource "aws_iam_role_policy_attachment" "ssm_attach" {
  role       = aws_iam_role.ec2_blog_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMFullAccess"
}

resource "aws_iam_role_policy_attachment" "cw_attach" {
  role       = aws_iam_role.ec2_blog_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

resource "aws_iam_role_policy_attachment" "ecr_managed_attach" {
  role       = aws_iam_role.ec2_blog_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_policy" "ec2_ecr_ssm" {
  name        = "EC2Blog-ECR-SSM-Policy"
  description = "Allow EC2 to authenticate to ECR, pull images, and read SSM parameters"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ECRGetAuth"
        Effect = "Allow"
        Action = ["ecr:GetAuthorizationToken"]
        Resource = "*"
      },
      {
        Sid    = "ECRPull"
        Effect = "Allow"
        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:DescribeImages",
          "ecr:DescribeRepositories",
          "ecr:ListImages"
        ]
        Resource = var.ecr_repo_arn
      },
      {
        Sid    = "SSMReadParameters"
        Effect = "Allow"
        Action = [
          "ssm:GetParameter",
          "ssm:GetParameters",
          "ssm:GetParameterHistory",
          "ssm:DescribeParameters"
        ]
        Resource = local.ssm_params_arns
      },
      {
        Sid    = "KMSDecryptForSSM"
        Effect = "Allow"
        Action = ["kms:Decrypt"]
        Resource = [local.kms_key_arn]
      },
      {
        Sid    = "ECRRepositoryAccess",
        Effect = "Allow"
        Action = [
          "ecr:GetRepositoryPolicy",
          "ecr:DescribeRepositories"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "attach_ec2_ecr_ssm" {
  role       = aws_iam_role.ec2_blog_role.name
  policy_arn = aws_iam_policy.ec2_ecr_ssm.arn
}

resource "aws_iam_instance_profile" "ec2_blog_profile" {
  name = "BlogEC2InstanceProfile"
  role = aws_iam_role.ec2_blog_role.name
}
