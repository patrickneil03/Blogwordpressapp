resource "aws_iam_role" "codebuild_role" {
  name = "codebuild-wordpress-blog-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "codebuild.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "codebuild_policy" {
  name = "codebuild-wordpress-blog-policy"
  role = aws_iam_role.codebuild_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      # 1. ECR Global Login Token (Must be "*")
      {
        Effect   = "Allow"
        Action   = ["ecr:GetAuthorizationToken"]
        Resource = "*"
      },
      # 2. Scope Down Read/Write Actions to just your ECR Repo
      {
        Effect = "Allow"
        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:GetRepositoryPolicy",
          "ecr:DescribeRepositories",
          "ecr:ListImages",
          "ecr:DescribeImages",
          "ecr:BatchGetImage",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload",
          "ecr:PutImage"
        ]
        # 🎯 FIX: Explicitly targets your repo resource
        Resource = [var.ecr_repo_arn] 
      },
      # 3. Secure S3 Artifact Interaction
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:GetBucketVersioning",
          "s3:PutObject",
          "s3:ListBucket"
        ]
        Resource = [
          "${var.codepipeline_artifacts_bucket_arn}",
          "${var.codepipeline_artifacts_bucket_arn}/*"
        ]
      },
      # 4. Cleaned & Combined Strict CloudWatch Logging
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        # 🎯 FIX: Consolidated and kept strictly limited to your project path
        Resource = [
          "arn:aws:logs:${var.region}:${var.account_id}:log-group:/aws/codebuild/wordpress-blog-deploy",
          "arn:aws:logs:${var.region}:${var.account_id}:log-group:/aws/codebuild/wordpress-blog-deploy:*"
        ]
      },
      # 5. Targeted Auto Scaling Actions
      {
        Effect = "Allow"
        Action = [
          "autoscaling:StartInstanceRefresh"
        ]
        # 🎯 FIX: CodeBuild can now only mutate your explicit target ASG
        Resource = [var.asg_arn]
      },
      # 6. Global ASG Read Operations (Required for tracking refresh status)
      {
        Effect = "Allow"
        Action = [
          "autoscaling:DescribeInstanceRefreshes",
          "autoscaling:DescribeAutoScalingGroups"
        ]
        Resource = "*"
      },

      # 7. Secure CloudFront Cache Invalidation
      {
        Sid    = "CloudFrontInvalidation"
        Effect = "Allow"
        Action = [
          "cloudfront:CreateInvalidation"
        ]
        # 🎯 FIX: Explicitly target the distribution ID from your error log
        Resource = ["arn:aws:cloudfront::${var.account_id}:distribution/${var.cf_distribution_id}"]
      }
    ]
  })
}