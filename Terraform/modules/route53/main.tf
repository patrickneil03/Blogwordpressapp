# Get your hosted zone
data "aws_route53_zone" "baylenwebsite" {
  name = "baylenwebsite.xyz."
}

# Create Route53 record pointing to CloudFront
resource "aws_route53_record" "blog_cloudfront" {
  zone_id = data.aws_route53_zone.baylenwebsite.zone_id
  name    = "blog.baylenwebsite.xyz"
  type    = "A"

  alias {
    name                   = var.cf_domain_name
    zone_id                = var.cf_zone_id
    evaluate_target_health = false
  }
}