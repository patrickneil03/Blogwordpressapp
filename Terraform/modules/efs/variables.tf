variable "efs_sg_id" {
  description = "The security group ID for the EFS."
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

variable "app_subnet_ids" {
  type        = list(string)  # ✅ Change from map to list
  description = "List of app subnet IDs for EFS mount targets"
}