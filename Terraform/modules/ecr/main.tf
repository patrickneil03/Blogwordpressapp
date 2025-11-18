resource "aws_ecr_repository" "wordpress_repo" {
  name                 = "wordpress-blog-ecr"
  image_tag_mutability = "MUTABLE" # or IMMUTABLE if you want strict versioning
  force_delete         = true

  encryption_configuration {
    encryption_type = "AES256"
  }

  tags = {
    Name = "wordpress-blog-ecr"
  }
}

resource "aws_ecr_lifecycle_policy" "wordpress_policy" {
  repository = aws_ecr_repository.wordpress_repo.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Expire untagged images after 7 days"
        selection = {
          tagStatus     = "untagged"
          countType     = "sinceImagePushed"
          countUnit     = "days"
          countNumber   = 7
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}
