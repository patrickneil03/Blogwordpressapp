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

variable "ami_version" {
  description = "Version number for the AMI"
  type        = string
  default     = "1.0.0"
}

variable "ecr_api_endpoint_id" {
  description = "The ecr api endpoint id"
  type        = string
}

variable "ecr_dkr_endpoint_id" {
  type = string
}

variable "s3_endpoint_id" {
  type = string
}

variable "efs_mount_target_ids" {
  type        = list(string)
  description = "List of EFS mount target IDs from the EFS module"
}

variable "rds_instance_id" {
  type        = string
  description = "The ID of the RDS instance to establish dependency"
}


variable "route53_subdomain_name" {
  type        = string
  description = "The subdomain name for the Wordpress blog"
}

variable "alb_certificate_arn" {
  type        = string
  description = "The ARN of the SSL certificate for the ALB"
}