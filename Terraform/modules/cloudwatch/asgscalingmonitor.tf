# CloudWatch alarm — scale out when average CPU > 40% for 2 consecutive periods (2 x 60s)
resource "aws_cloudwatch_metric_alarm" "cpu_high_scale_out" {
  alarm_name          = "asg-wordpress-cpu-high"
  alarm_description   = "Scale out when ASG average CPU > 40%."
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 60
  statistic           = "Average"
  threshold           = 40.0

  dimensions = {
    AutoScalingGroupName = var.asg_wordpress_blog_name
  }

  alarm_actions = [var.asg_policy_scale_out_cpu_arn]
  treat_missing_data = "notBreaching"
}

# CloudWatch alarm — scale in when average CPU <= 40% for 5 consecutive periods (5 x 60s)
resource "aws_cloudwatch_metric_alarm" "cpu_low_scale_in" {
  alarm_name          = "asg-wordpress-cpu-low"
  alarm_description   = "Scale in when ASG average CPU <= 40%."
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = 5
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 60
  statistic           = "Average"
  threshold           = 40.0

  dimensions = {
    AutoScalingGroupName = var.asg_wordpress_blog_name
  }

  alarm_actions = [var.asg_policy_scale_in_cpu_arn]
  treat_missing_data = "notBreaching"
}