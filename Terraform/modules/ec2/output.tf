/*output "security_group_ids" {
  description = "The IDs of the security groups attached to the launch template."
  value       = aws_security_group.goingtointernet.id
  
}*/

output "rds_sg_id" {
  description = "The ID of the RDS security group."
  value       = aws_security_group.rds.id
  
}

output "efs_sg_id" {
  description = "The ID of the EFS security group."
  value       = aws_security_group.efs.id
  
}

output "vpc_endpoint_sg_id" {
  description = "The ID of the EFS security group."
  value       = aws_security_group.vpc_endpoint.id
  
}

output "asg_policy_scale_out_cpu_arn" {
  description = "The ARN of the ASG scale-out CPU policy."
  value       = aws_autoscaling_policy.asg_scale_out_cpu.arn
  
}

output "asg_policy_scale_in_cpu_arn" {
  description = "The ARN of the ASG scale-in CPU policy."
  value       = aws_autoscaling_policy.asg_scale_in_cpu.arn
  
}

output "asg_wordpress_blog_name" {
  description = "The name of the Auto Scaling Group for Wordpress blog."
  value       = aws_autoscaling_group.asg_wordpress_blog.name
  
}

output "alb_dns_name" {
  description = "The DNS name of the Application Load Balancer"
  value       = aws_lb.blogwordpressALB.dns_name
}

output "asg_name" {
  value = aws_autoscaling_group.asg_wordpress_blog.name
}

# Output AMI ID
output "ami_id_output" {
  value = aws_ami_from_instance.wordpress_ami.id
}

output "usage" {
  value = <<-EOT
  ✅ AMI created: ${aws_ami_from_instance.wordpress_ami.id}
  
  Use this in your launch template:
  
  resource "aws_launch_template" "wordpress" {
    image_id = "${aws_ami_from_instance.wordpress_ami.id}"
    # ... other config
  }
  EOT
}


