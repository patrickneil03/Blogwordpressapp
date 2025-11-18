variable "asg_policy_scale_out_cpu_arn" {
  description = "The ARN of the ASG scale-out CPU policy."
  type        = string
  
}

variable "asg_policy_scale_in_cpu_arn" {
  description = "The ARN of the ASG scale-in CPU policy."
  type        = string
  
}

variable "asg_wordpress_blog_name" {
  description = "The name of the Auto Scaling Group for Wordpress blog."
  type        = string
  
}