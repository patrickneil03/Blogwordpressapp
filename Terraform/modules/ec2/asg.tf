resource "aws_autoscaling_group" "asg_wordpress_blog" {
  name                 = "asg-wordpress-blog"
  launch_template {
    id      = aws_launch_template.wordpress_blog.id
    version = "$Latest"
  }

  # FIX: target_group_arns must be a list, and we reference the ARN attribute
  target_group_arns = [aws_lb_target_group.blog_asg_tg.arn]

  # Using var.pub_subnet_ids as specified, which should contain the list of Public Subnet IDs
  vpc_zone_identifier = var.app_subnet_ids
  min_size            = 2
  max_size            = 4
  desired_capacity    = 3

  # Health check settings for connection with the Load Balancer
  health_check_type         = "ELB" # Changed to ELB to use the Target Group health checks
  health_check_grace_period = 300

  lifecycle {
    create_before_destroy = true
  }

  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 50
      instance_warmup        = 300
    }
    triggers = ["tag"]  # Refresh when tags change
  }

  tag {
    key                 = "Name"
    value               = "Wordpress-blog-ASG"
    propagate_at_launch = true
  }
}






#ASG POLICY

# Scale-out policy: add 1 instance
resource "aws_autoscaling_policy" "asg_scale_out_cpu" {
  name                   = "asg-wordpress-scale-out-cpu"
  autoscaling_group_name = aws_autoscaling_group.asg_wordpress_blog.name
  policy_type            = "SimpleScaling"
  adjustment_type        = "ChangeInCapacity"
  scaling_adjustment     = 1
  cooldown               = 300
}

# Scale-in policy: remove 1 instance
resource "aws_autoscaling_policy" "asg_scale_in_cpu" {
  name                   = "asg-wordpress-scale-in-cpu"
  autoscaling_group_name = aws_autoscaling_group.asg_wordpress_blog.name
  policy_type            = "SimpleScaling"
  adjustment_type        = "ChangeInCapacity"
  scaling_adjustment     = -1
  cooldown               = 300
}