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

  # STAGE 2: Optimized Build & Deploy combined
  stage {
    name = "BuildAndDeploy"
    action {
      name             = "BuildAndDeployAction"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      version          = "1"
      input_artifacts  = ["source_output"]
      output_artifacts = ["deploy_output"]

      configuration = {
        ProjectName = var.codebuild_deploy_name
      }
    }
  }
}