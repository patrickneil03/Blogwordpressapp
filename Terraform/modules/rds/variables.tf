variable "db_subnet_ids" {
  description = "List of DB subnet IDs for RDS (DB-subnet-A, DB-subnet-B, DB-subnet-C)"
  type        = list(string)
  
}

variable "DBUser" {
  description = "The database username."
  type        = string
  sensitive = true
  
}

variable "DBPassword" {
  description = "The password for the database user."
  type        = string
  sensitive   = true
  
}

variable "DBName" {
  description = "The name of the database."
  type        = string
  sensitive = true
  
}

variable "db_engine_version" {
  description = "The version of the database engine."
  type        = string
}

variable "db_allocated_storage" {
  description = "The allocated storage in gigabytes."
  type        = number
  
}

variable "db_instance_class" {
  description = "The instance class for the RDS instance."
  type        = string
  
}

variable "rds_sg_id" {
  description = "The security group ID for the RDS instance."
  type        = string
  
}