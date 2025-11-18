output "codebuild_build_name" {
  value = aws_codebuild_project.wordpress_build.name
}

output "codebuild_deploy_name" {
  value = aws_codebuild_project.wordpress_deploy.name
}