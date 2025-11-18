# CloudWatch Log Group for CodeBuild
resource "aws_cloudwatch_log_group" "codebuild_logs" {
  name              = "/aws/codebuild/wordpress-blog-build"
  retention_in_days = 30  # Keep logs for 30 days

  tags = {
    Name = "wordpress-blog-codebuild-logs"
  }
}

resource "aws_cloudwatch_log_group" "deploy_logs" {
  name              = "/aws/codebuild/wordpress-blog-deploy"
  retention_in_days = 30
}