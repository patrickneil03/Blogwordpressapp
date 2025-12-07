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

variable "ami_id" {
  description = "the pre baked ami for auto scaling group"
}