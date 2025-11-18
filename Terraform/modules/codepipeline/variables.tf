variable "codebuild_build_name" {
  description = "the name of the codebuild project for build stage for wordpress app"
}

variable "codebuild_deploy_name" {
  description = "the name of the codebuild project for deploy stage for wordpress app"
}

variable "codestar_connection_arn" {
  description = "the arn of the codestar connection"
}

variable "github_repo" {
  description = "the name of the github repo for wordpress app"
}

variable "codepipeline_role_arn" {
  description = "the arn of codepipeline role"
}

variable "artifacts_bucket" {
  description = "the bucket for artifacts"
}