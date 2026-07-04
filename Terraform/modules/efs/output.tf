output "efs_id" {
  description = "The id of efs filesystem"
  value       = aws_efs_file_system.blog_efs.id
}

output "efs_mount_target_ids" {
  description = "List of EFS mount target IDs"
  value       = aws_efs_mount_target.blog_mount_targets[*].id
}

output "efs_wordpress_blog_arn" {
  description = "ARN of the EFS filesystem for Wordpress blog"
  value       = aws_efs_file_system.blog_efs.arn

}