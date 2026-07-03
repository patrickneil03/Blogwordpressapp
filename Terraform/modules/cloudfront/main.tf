resource "aws_cloudfront_distribution" "wordpress" {
  enabled         = true
  is_ipv6_enabled = true
  comment         = "WordPress blog distribution"
  price_class     = "PriceClass_All"
  aliases         = [var.route53_subdomain_name]

  origin {
    domain_name = var.alb_dns_name
    origin_id   = "alb-origin"

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "https-only"
      origin_ssl_protocols   = ["TLSv1.2", "TLSv1.1", "TLSv1"]
      origin_read_timeout    = 30
    }

    # Add custom header for ALB access
    custom_header {
      name  = "X-Forwarded-Host"
      value = var.route53_subdomain_name
    }
  }

  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "alb-origin"

    forwarded_values {
      query_string = true
      headers      = ["*"] # Forward all headers
      cookies {
        forward = "all"
      }
    }

    min_ttl                = 0
    default_ttl            = 300
    max_ttl                = 1200
    compress               = true
    viewer_protocol_policy = "redirect-to-https"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn      = var.cloudfront_certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  tags = {
    Name = "wordpress-blog-cdn"
  }

  depends_on = [
    var.cloudfront_certificate_arn
  ]
}