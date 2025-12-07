variable "region" {
  description = "The AWS region to create resources in."
  type        = string
  default     = "ap-southeast-1"
  
}

variable "vpc_cidr" {
  description = "The CIDR block for the VPC."
  type        = string
  
}

variable "Project" {
  description = "The project name."
  type        = string
  
}

variable "Env" {
  description = "The environment name."
  type        = string
  
}

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

variable "codestar_connection_arn" {
  description = "The ARN of the CodeStar connection."
  type        = string
  sensitive = true
}

variable "github_owner" {
  description = "the username of my github account"
}

variable "github_repo" {
  description = "the name of the github repo for wordpress app"
}

variable "github_branch" {
  description = "the branch to use in the github repo of wordpress app"
  
}

variable "account_id" {
  description = "my current account id for aws account"
}

variable "ami_id" {
  description = "the pre baked ami id for my ec2 instances"
  
}
