resource "aws_codebuild_project" "wordpress_deploy" {
  name          = "wordpress-blog-deploy"
  description   = "Unified build, push to ECR, and Fargate deploy trigger project"
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
    # REPLACED ASG_NAME WITH ECS VARIABLES
    environment_variable {
      name  = "ECS_CLUSTER_NAME"
      value = "wordpress-prod-cluster"
    }
    environment_variable {
      name  = "ECS_SERVICE_NAME"
      value = "wordpress-service"
    }
  }

  source {
    type = "CODEPIPELINE"
    buildspec = yamlencode({
      version = "0.2"
      phases = {
        pre_build = {
          commands = [
            "echo 'Logging in to Amazon ECR...'",
            "aws ecr get-login-password --region $AWS_DEFAULT_REGION | docker login --username AWS --password-stdin $AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com"
          ]
        }
        build = {
          commands = [
            "echo 'Building and tagging optimized Docker image...'",
            "docker build -t $IMAGE_REPO_NAME:$IMAGE_TAG .",
            "docker tag $IMAGE_REPO_NAME:$IMAGE_TAG $AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com/$IMAGE_REPO_NAME:$IMAGE_TAG",
            "echo 'Pushing Docker image directly to ECR...'",
            "docker push $AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com/$IMAGE_REPO_NAME:$IMAGE_TAG"
          ]
        }
        post_build = {
          commands = [
            "echo 'Triggering ECS Fargate rolling deployment...'",
            "aws ecs update-service --cluster $ECS_CLUSTER_NAME --service $ECS_SERVICE_NAME --force-new-deployment --region $AWS_DEFAULT_REGION",
            "echo 'Invalidating CloudFront caches...'",
            "aws cloudfront create-invalidation --distribution-id $CLOUDFRONT_ID --paths '/*'",
            "echo 'Deployment to AWS Fargate processed successfully!'"
          ]
        }
      }
    })
  }

  tags = {
    Name = "wordpress-blog-deploy"
  }
}