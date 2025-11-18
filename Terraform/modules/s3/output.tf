output "codepipeline_artifacts_bucket_arn" {
  description = "The arn of the S3 bucket for codepipeline artifacts."
  value = aws_s3_bucket.codepipeline_artifacts.arn
  
}

output "artifacts_bucket" {
  value = aws_s3_bucket.codepipeline_artifacts.bucket
}