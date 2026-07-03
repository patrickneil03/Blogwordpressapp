output "alb_domain_validation_options" {
  value       = aws_acm_certificate.alb_cert.domain_validation_options
  description = "Raw validation attributes passed to the Route 53 module"
}

output "cloudfront_domain_validation_options" {
  value       = aws_acm_certificate.cloudfront_cert.domain_validation_options
  description = "Raw validation attributes passed to the Route 53 module"
}

# Export the certificates for the validation loops
output "alb_certificate_arn" { value = aws_acm_certificate.alb_cert.arn }
output "cloudfront_certificate_arn" { value = aws_acm_certificate.cloudfront_cert.arn }