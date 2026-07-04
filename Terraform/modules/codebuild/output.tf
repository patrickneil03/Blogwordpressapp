output "codebuild_deploy_name" {
  value = aws_codebuild_project.wordpress_deploy.name
}

output "coldebuild_wordpress_blog_arn" {
  value = aws_codebuild_project.wordpress_deploy.arn

}