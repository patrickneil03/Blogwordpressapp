# Get your hosted zone
data "aws_route53_zone" "baylenwebsite" {
  name = var.route53_domain_name
}

# Create Route53 record pointing to CloudFront
resource "aws_route53_record" "blog_cloudfront" {
  zone_id = data.aws_route53_zone.baylenwebsite.zone_id
  name    = var.route53_subdomain_name
  type    = "A"

  alias {
    name                   = var.cf_domain_name
    zone_id                = var.cf_zone_id
    evaluate_target_health = false
  }
}


resource "aws_route53_record" "alb_validation" {
  for_each        = { for dvo in var.alb_domain_validation_options : dvo.domain_name => dvo }
  allow_overwrite = true
  name            = each.value.resource_record_name
  records         = [each.value.resource_record_value]
  ttl             = 60
  type            = each.value.resource_record_type
  zone_id         = data.aws_route53_zone.baylenwebsite.zone_id
}

# 🎯 NEW: Moved CloudFront DNS Validation Record here
resource "aws_route53_record" "cloudfront_validation" {
  for_each        = { for dvo in var.cloudfront_domain_validation_options : dvo.domain_name => dvo }
  allow_overwrite = true
  name            = each.value.resource_record_name
  records         = [each.value.resource_record_value]
  ttl             = 60
  type            = each.value.resource_record_type
  zone_id         = data.aws_route53_zone.baylenwebsite.zone_id
}