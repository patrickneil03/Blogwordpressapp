variable "region" {
  default = "ap-southeast-1"
}

variable "account_id" {
  description = "the current account id for this aws account"
}

variable "cf_distribution_id" {
  description = "the id of cloudfront distribution for wordpress app"
}

variable "codebuild_role_arn" {
  description = "the arn of iam role for codebuild"
}

variable "asg_name" {
  description = "name of the autoscaling group for wordpress"
}