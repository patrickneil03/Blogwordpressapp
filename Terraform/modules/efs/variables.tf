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
  description = "A map of App subnet IDs (Name => ID) for EFS mount targets."
  type        = map(string)
}