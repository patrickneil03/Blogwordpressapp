terraform {
  backend "s3" {
    bucket         = "baylenweb-tf-state-storage"
    
    key            = "prod/wordpress/terraform.tfstate"
    
    region         = "ap-southeast-1"
    
    dynamodb_table = "baylenweb-tf-state-locking-table"
    
    encrypt        = true
  }
}