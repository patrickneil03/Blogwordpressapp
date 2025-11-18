output "efs_id_output" {
  value = module.efs.efs_id
}

output "alb_dns_name_output" {
  value = module.ec2.alb_dns_name
}

output "rds_endpoint_output" {
  value = module.rds.rds_endpoint
}

output "ecr_repository_url_output" {
  value = module.ecr.ecr_repository_url
}

output "cf_zone_id_output" {
  value = module.cloudfront.cf_zone_id
}