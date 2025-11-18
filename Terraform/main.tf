terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.0.0"
    }
  }
  
}

provider "aws" {
  region = var.region
  
}

module "vpc" {
  source = "./modules/vpc"
  vpc_cidr = var.vpc_cidr
  Project = var.Project
  Env     = var.Env
  
}

module "ec2" {
  source = "./modules/ec2"
  vpc_id = module.vpc.vpc_id
  instance_profile_name = module.iam.instance_profile_name
  pub_subnet_ids = module.vpc.pub_subnet_ids
}

module "parameterstore" {
  source = "./modules/parameterstore"
  DBPassword     = var.DBPassword
  DBRootPassword = var.DBRootPassword
  DBUser         = var.DBUser
  DBName         = var.DBName
  efs_id         = module.efs.efs_id
  alb_dns_name   = module.ec2.alb_dns_name
  rds_endpoint   = module.rds.rds_endpoint 
}

module "iam" {
  source = "./modules/iam"
  ecr_repo_arn = module.ecr.ecr_repo_arn
  codepipeline_artifacts_bucket_arn = module.s3.codepipeline_artifacts_bucket_arn
  codestar_connection_arn = var.codestar_connection_arn
  account_id = var.account_id

}

module "rds" {
  source = "./modules/rds"
  db_subnet_ids = module.vpc.db_subnet_ids
  rds_sg_id = module.ec2.rds_sg_id
  DBUser         = var.DBUser
  DBPassword     = var.DBPassword
  db_engine_version = var.db_engine_version
  db_allocated_storage = var.db_allocated_storage
  db_instance_class = var.db_instance_class
  DBName = var.DBName

}

module "efs" {
  source = "./modules/efs"
  efs_sg_id = module.ec2.efs_sg_id
  Project = var.Project
  Env     = var.Env
  app_subnet_ids = module.vpc.app_subnet_ids
}

module "cloudwatch" {
  source = "./modules/cloudwatch"
  asg_wordpress_blog_name = module.ec2.asg_wordpress_blog_name
  asg_policy_scale_out_cpu_arn = module.ec2.asg_policy_scale_out_cpu_arn
  asg_policy_scale_in_cpu_arn = module.ec2.asg_policy_scale_in_cpu_arn
  
}

module "ecr"{
  source = "./modules/ecr"
}

module "cloudfront"{
  source = "./modules/cloudfront"
  alb_dns_name = module.ec2.alb_dns_name
}

module "route53"{
  source = "./modules/route53"
  cf_domain_name = module.cloudfront.cf_domain_name
  cf_zone_id = module.cloudfront.cf_zone_id
}

module "s3"{
  source = "./modules/s3"
}

module "codebuild"{
  source = "./modules/codebuild"
  codebuild_role_arn = module.iam.codebuild_role_arn
  cf_distribution_id = module.cloudfront.cf_distribution_id
  account_id = var.account_id
  region = var.region
  asg_name = module.ec2.asg_name
}

module "codepipeline"{
  source = "./modules/codepipeline"
  codepipeline_role_arn = module.iam.codepipeline_role_arn
  codestar_connection_arn = var.codestar_connection_arn
  github_repo = var.github_repo
  artifacts_bucket = module.s3.artifacts_bucket
  codebuild_build_name = module.codebuild.codebuild_build_name
  codebuild_deploy_name = module.codebuild.codebuild_deploy_name
}