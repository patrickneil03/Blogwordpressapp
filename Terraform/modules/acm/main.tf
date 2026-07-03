terraform {
  required_providers {
    aws = {
      source                = "hashicorp/aws"
      version               = "~> 5.0"
      configuration_aliases = [aws.us_east_1] # 🎯 This tells module.acm to expect BOTH aws and aws.us_east_1
    }
  }
}


data "aws_route53_zone" "baylenwebsite" {
  name         = var.route53_domain_name
  private_zone = false
}


resource "aws_acm_certificate" "alb_cert" {
  domain_name       = var.route53_subdomain_name
  validation_method = "DNS"

  lifecycle { create_before_destroy = true }
  tags = { Name = "alb-singapore-cert" }
}

# ==============================================================================
# 🇺🇸 US-EAST-1: REQUEST CLOUDFRONT CERTIFICATE
# ==============================================================================
resource "aws_acm_certificate" "cloudfront_cert" {
  provider          = aws.us_east_1
  domain_name       = var.route53_subdomain_name
  validation_method = "DNS"

  lifecycle { create_before_destroy = true }
  tags = { Name = "cloudfront-virginia-cert" }
}





