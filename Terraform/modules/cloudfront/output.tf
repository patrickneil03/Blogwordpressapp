output "cf_domain_name" {
  value = aws_cloudfront_distribution.wordpress.domain_name
}

output "cf_zone_id" {
  value = aws_cloudfront_distribution.wordpress.hosted_zone_id
}

output "cf_distribution_id" {
 value = aws_cloudfront_distribution.wordpress.id 
}