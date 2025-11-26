# CodePipeline with 3 Stages
resource "aws_codepipeline" "wordpress_pipeline" {
  name     = "wordpress-blog-pipeline"
  role_arn = var.codepipeline_role_arn

  artifact_store {
    location = var.artifacts_bucket
    type     = "S3"
  }

  # STAGE 1: Source
  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeStarSourceConnection"
      version          = "1"
      output_artifacts = ["source_output"]

      configuration = {
        ConnectionArn    = var.codestar_connection_arn
        FullRepositoryId = "${var.github_owner}/${var.github_repo}"
        BranchName       = "main"
      }
    }
  }

  # STAGE 2: Build - Only builds Docker image
  stage {
    name = "Build"

    action {
      name             = "Build"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      version          = "1"
      input_artifacts  = ["source_output"]
      output_artifacts = ["build_output"]

      configuration = {
        ProjectName = var.codebuild_build_name
      }
    }
  }

  # STAGE 3: Deploy - Pushes to ECR, refreshes ASG, invalidates cache
  stage {
    name = "Deploy"

    action {
      name            = "Deploy"
      category        = "Build"
      owner           = "AWS"
      provider        = "CodeBuild"
      version         = "1"
      input_artifacts = ["source_output"]  # Changed from build_output to source_output

      configuration = {
        ProjectName = var.codebuild_deploy_name
      }
    }
  }
}