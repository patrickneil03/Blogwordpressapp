resource "aws_autoscaling_group" "asg_wordpress_blog" {
  name             = "asg-wordpress-blog-v${var.ami_version}"
  min_size         = 2
  max_size         = 4
  desired_capacity = 3
  
  vpc_zone_identifier = var.app_subnet_ids # Private subnets
  target_group_arns   = [aws_lb_target_group.blog_asg_tg.arn]

  launch_template {
    id      = aws_launch_template.wordpress_blog.id
    version = "$Latest"
  }

  # THE FIXES:
  health_check_type         = "ELB"
  health_check_grace_period = 600 # 10 minutes buffer
  
  # Ensure networking/DB is ready before ASG starts
  depends_on = [
    var.ecr_api_endpoint_id,
    var.ecr_dkr_endpoint_id,
    var.s3_endpoint_id,
    var.efs_mount_target_ids,
    var.rds_instance_id
  ]

  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 50
      instance_warmup        = 300 
    }
  }

  lifecycle {
    create_before_destroy = true
  }

  tag {
    key                 = "Name"
    value               = "Wordpress-blog-ASG"
    propagate_at_launch = true
  }
}

# --- SCALE OUT POLICY ---
resource "aws_autoscaling_policy" "asg_scale_out_cpu" {
  name                   = "asg-wordpress-scale-out"
  autoscaling_group_name = aws_autoscaling_group.asg_wordpress_blog.name
  policy_type            = "SimpleScaling"
  adjustment_type        = "ChangeInCapacity"
  scaling_adjustment     = 1
  cooldown               = 300
}

# --- SCALE IN POLICY ---
resource "aws_autoscaling_policy" "asg_scale_in_cpu" {
  name                   = "asg-wordpress-scale-in"
  autoscaling_group_name = aws_autoscaling_group.asg_wordpress_blog.name
  policy_type            = "SimpleScaling"
  adjustment_type        = "ChangeInCapacity"
  scaling_adjustment     = -1
  cooldown               = 300
}