resource "aws_s3_bucket" "codepipeline_artifacts" {
  bucket = "wordpress-blog-pipeline-artifacts-${random_id.bucket_suffix.hex}"
  force_destroy = true  # This allows non-empty bucket deletion
}

resource "random_id" "bucket_suffix" {
  byte_length = 8
}

# Add this for security (blocks public access)
resource "aws_s3_bucket_public_access_block" "codepipeline_artifacts" {
  bucket = aws_s3_bucket.codepipeline_artifacts.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}