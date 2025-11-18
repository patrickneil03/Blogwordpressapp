# CodeBuild Project for BUILD Stage
resource "aws_codebuild_project" "wordpress_build" {
  name          = "wordpress-blog-build"
  description   = "Build WordPress Docker image"
  service_role  = var.codebuild_role_arn
  build_timeout = 15

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type    = "BUILD_GENERAL1_MEDIUM"
    image           = "aws/codebuild/amazonlinux2-x86_64-standard:3.0"
    type            = "LINUX_CONTAINER"
    privileged_mode = true

    environment_variable {
      name  = "IMAGE_REPO_NAME"
      value = "wordpress-blog-ecr"
    }
    environment_variable {
      name  = "IMAGE_TAG"
      value = "latest"
    }
  }

  source {
    type = "CODEPIPELINE"
    buildspec = <<-EOT
      version: 0.2
      
      phases:
        pre_build:
          commands:
            - echo "=== DEBUG: Checking Dockerfile ==="
            - echo "Line 18 content:"
            - sed -n '18p' Dockerfile
            - echo "Full Dockerfile head:"
            - head -25 Dockerfile
        build:
          commands:
            - echo "Building Docker image..."
            - docker build -t $IMAGE_REPO_NAME:$IMAGE_TAG .
            - echo "Docker image built successfully"
    EOT
  }

  tags = {
    Name = "wordpress-blog-build"
  }
}

# CodeBuild Project for DEPLOY Stage
resource "aws_codebuild_project" "wordpress_deploy" {
  name          = "wordpress-blog-deploy"
  description   = "Push Docker image to ECR and deploy"
  service_role  = var.codebuild_role_arn
  build_timeout = 15

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type    = "BUILD_GENERAL1_MEDIUM"
    image           = "aws/codebuild/amazonlinux2-x86_64-standard:3.0"
    type            = "LINUX_CONTAINER"
    privileged_mode = true

    environment_variable {
      name  = "AWS_DEFAULT_REGION"
      value = var.region
    }
    environment_variable {
      name  = "AWS_ACCOUNT_ID"
      value = var.account_id
    }
    environment_variable {
      name  = "IMAGE_REPO_NAME"
      value = "wordpress-blog-ecr"
    }
    environment_variable {
      name  = "IMAGE_TAG"
      value = "latest"
    }
    environment_variable {
      name  = "CLOUDFRONT_ID"
      value = var.cf_distribution_id
    }
    environment_variable {
      name  = "ASG_NAME"
      value = var.asg_name
    }
  }

  source {
    type = "CODEPIPELINE"
    buildspec = <<-EOT
      version: 0.2
      
      phases:
        pre_build:
          commands:
            - echo "Logging in to Amazon ECR..."
            - aws ecr get-login-password --region $AWS_DEFAULT_REGION | docker login --username AWS --password-stdin $AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com
            - echo "Preparing Docker image..."
        build:
          commands:
            - echo "Tagging Docker image for ECR..."
            - docker tag $IMAGE_REPO_NAME:$IMAGE_TAG $AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com/$IMAGE_REPO_NAME:$IMAGE_TAG
            - echo "Pushing Docker image to ECR..."
            - docker push $AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com/$IMAGE_REPO_NAME:$IMAGE_TAG
            - echo "Triggering ASG instance refresh..."
            - aws autoscaling start-instance-refresh --auto-scaling-group-name $ASG_NAME --strategy Rolling --preferences MinHealthyPercentage=90,InstanceWarmup=300
            - echo "Invalidating CloudFront cache..."
            - aws cloudfront create-invalidation --distribution-id $CLOUDFRONT_ID --paths "/*"
            - echo "Deployment completed successfully"
    EOT
  }

  tags = {
    Name = "wordpress-blog-deploy"
  }
}