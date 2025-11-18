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
    buildspec = "buildspec-build.yml"  # ← CHANGED: Reference external file
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
    buildspec = "buildspec-deploy.yml"  # ← CHANGED: Reference external file
  }

  tags = {
    Name = "wordpress-blog-deploy"
  }
}