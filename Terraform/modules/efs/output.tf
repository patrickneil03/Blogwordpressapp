output "efs_id" {
  description = "The id of efs filesystem"
  value = aws_efs_file_system.blog_efs.id
}