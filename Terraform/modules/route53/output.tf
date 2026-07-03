output "alb_validation_fqdns" {
  value = [for record in aws_route53_record.alb_validation : record.fqdn]
}

output "cloudfront_validation_fqdns" {
  value = [for record in aws_route53_record.cloudfront_validation : record.fqdn]
}

# Simple pass-through output so root can access zone ID if needed
output "zone_id" {
  value = data.aws_route53_zone.baylenwebsite.zone_id
}