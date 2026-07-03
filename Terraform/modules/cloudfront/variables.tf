variable "alb_dns_name" {
  description = "dns name of wordpress application loadbalancer"
}

variable "route53_subdomain_name" {
  description = "the subdomain name for the wordpress blog"
}

variable "cloudfront_certificate_arn" {
  description = "the arn of the cloudfront certificate"
}