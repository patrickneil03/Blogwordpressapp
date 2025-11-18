variable "vpc_name" {
  description = "The name of the VPC."
  type        = string
  default     = "blog-vpc"
  
}

variable "vpc_cidr" {
  description = "The CIDR block for the VPC."
  type        = string
  
}

variable "public_subnet_cidrs" {
  description = "List of CIDR blocks for public subnets."
  type        = string
  default     = "10.0.0.0/24"
  
}

variable "region" {
  description = "The AWS region to create resources in."
  type        = string
  default     = "ap-southeast-1"
  
}

variable "igw_name" {
  description = "The name of the Internet Gateway."
  type        = string
  default     = "blog-igw"
  
}

variable "Project" {
  description = "The project name."
  type        = string
  
}

variable "Env" {
  description = "The environment name."
  type        = string
  
}

variable "ipv6_index_offset" {
  type    = number
  default = 0
}