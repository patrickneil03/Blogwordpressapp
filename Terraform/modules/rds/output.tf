# In your modules/rds/outputs.tf
output "rds_endpoint" {
  description = "The connection endpoint for the RDS instance"
  value       = aws_db_instance.blogrds.endpoint
}