variable "cf_domain_name" {
  description = "cloudfront distribution domain name for wordpress"
}

variable "cf_zone_id" {
  description = "zone id for my wordpress cloudfront distribution"
}

variable "route53_domain_name" {
  description = "domain name for route53"
}

variable "route53_subdomain_name" {
  description = "subdomain name for route53"
}

variable "alb_domain_validation_options" { type = any }

variable "cloudfront_domain_validation_options" { type = any }