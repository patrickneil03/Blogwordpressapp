locals {
  base_path = "/BLOG/Wordpress"
}

resource "aws_ssm_parameter" "db_password" {
  name        = "${local.base_path}/DBPassword"
  description = "Database user password for WordPress"
  type        = "SecureString"
  value       = var.DBPassword
  tags        = { Project = "BLOG" }
  key_id      = length(trimspace(var.kms_key_id)) > 0 ? var.kms_key_id : null
}

resource "aws_ssm_parameter" "db_root_password" {
  name        = "${local.base_path}/DBRootPassword"
  description = "Database root password for WordPress"
  type        = "SecureString"
  value       = var.DBRootPassword
  tags        = { Project = "BLOG" }
  key_id      = length(trimspace(var.kms_key_id)) > 0 ? var.kms_key_id : null
}

resource "aws_ssm_parameter" "db_user" {
  name        = "${local.base_path}/DBUser"
  description = "Database username for WordPress"
  type        = "String"
  value       = var.DBUser
  tags        = { Project = "BLOG" }
}

resource "aws_ssm_parameter" "db_name" {
  name        = "${local.base_path}/DBName"
  description = "Database name for WordPress"
  type        = "String"
  value       = var.DBName
  tags        = { Project = "BLOG" }
}

resource "aws_ssm_parameter" "db_endpoint" {
  name          = "${local.base_path}/DBEndpoint"
  description   = "Database endpoint for WordPress"
  type          = "String"
  tier          = "Standard"
  data_type     = "text"
  
  # FIX: Use the replace function to find ":3306" at the end of the string
  # and replace it with an empty string ("").
  value         = replace(var.rds_endpoint, ":3306", "")
  
  tags          = { Project = "BLOG" }
}

resource "aws_ssm_parameter" "file_system_id" {
  name        = "${local.base_path}/EFSFileSystemID"
  description = "EFS File System ID for WordPress"
  type        = "String"
  tier        = "Standard"
  data_type   = "text"
  tags        = { Project = "BLOG" }
  value       = var.efs_id
}

resource "aws_ssm_parameter" "alb_dns_name" {
  name        = "${local.base_path}/ALBDNSName"
  description = "dns name of the ALB for WordPress"
  type        = "String"
  tier        = "Standard"
  data_type   = "text"
  tags        = { Project = "BLOG" }
  value       = var.alb_dns_name
}


