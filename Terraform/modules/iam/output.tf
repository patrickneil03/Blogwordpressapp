output "instance_profile_name" {
  description = "The name of the IAM instance profile for EC2."
  value       = aws_iam_instance_profile.ec2_blog_profile.name
  
}

output "codebuild_role_arn" {
  value = aws_iam_role.codebuild_role.arn
}

output "codepipeline_role_arn" {
  value = aws_iam_role.codepipeline_role.arn
}