output "ecr_repository_url" {
  value = aws_ecr_repository.wordpress_repo.repository_url
}

output "ecr_repo_arn" {
  description = "ARN of the ECR repository"
  value       = aws_ecr_repository.wordpress_repo.arn
}
