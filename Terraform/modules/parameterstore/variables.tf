variable "DBPassword" {
  description = "The password for the database user."
  type        = string
  sensitive   = true
  
}

variable "DBRootPassword" {
  description = "The password for the database root user."
  type        = string
  sensitive   = true
  
}

variable "DBUser" {
  description = "The database username."
  type        = string
  sensitive = true
}

variable "DBName" {
  description = "The name of the database."
  type        = string
  sensitive = true
  
}


variable "kms_key_id" {
  description = "Optional KMS key ARN or id to encrypt SecureString parameters. Leave empty to use default AWS managed key."
  type        = string
  default     = ""
}

variable "efs_id" {
  description = "The EFS Filesystem ID."
  type        = string
 
}

variable "alb_dns_name" {
  description = "DNS Name of application loadbalancer for wordpress blog"
}

variable "rds_endpoint" {
  description = "rds blog wordpress endpoint"
}
