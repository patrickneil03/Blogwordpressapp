variable "vpc_id" {
  description = "The ID of the VPC."
  type        = string
  
}


variable "instance_profile_name" {
  description = "Existing IAM instance profile name to attach (not ARN)"
  type        = string
}

# Optional: override AMI filters if needed
variable "ami_name_filter" {
  description = "AMI name filter to find Amazon Linux 2023 kernel 6.1 AMI"
  type        = string
  default     = "amzn-ami-kernel-6.1-*-x86_64*"
}

variable "pub_subnet_ids" {
  description = "Public subnets"
}

variable "app_subnet_ids" {
  description = "App private subnets"
}

variable "ami_id" {
  description = "the pre baked ami for auto scaling group"
}

variable "region" {
  default = "ap-southeast-1"
}

variable "account_id_output" {
  description = "the output of account id"
}

variable "vpc_cidr" {
  description = "The CIDR block for the VPC."
  type        = string
}