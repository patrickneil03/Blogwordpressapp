variable "kms_key_id" {
  description = "Optional KMS key ARN or id to encrypt SecureString parameters. Leave empty to use default AWS managed key."
  type        = string
  default     = ""
}

variable "ecr_repo_arn" {
  description = "ARN of the ECR repository"
}


variable "region" {
  description = "AWS region for constructing ARNs"
  type        = string
  default     = "ap-southeast-1"
}

variable "codestar_connection_arn" {
  description = "the arn of codestar connection"
}

variable "codepipeline_artifacts_bucket_arn" {
  description = "the arn of s3 bucker artifacts"
}

variable "account_id" {
  description = "account id of aws account for wordpress blog"
}