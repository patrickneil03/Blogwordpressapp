resource "aws_lb_target_group" "blog_asg_tg" {
  name            = "blog-asg-tg"
  target_type     = "instance"
  port            = 80
  protocol        = "HTTP"
  vpc_id          = var.vpc_id
  ip_address_type = "ipv4"

  stickiness {
    enabled         = true
    type            = "lb_cookie"
    cookie_duration = 86400
  }

  health_check {
    protocol            = "HTTP"
    path                = "/health.php" # Target our fast, lightweight endpoint
    matcher             = "200"         # Looking for explicit 200 OK responses
    interval            = 15            # Check every 15s instead of 30s to cycle instances faster
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  tags = {
    Name    = "blog-asg-tg"
    Project = "BLOG"
    Managed = "terraform"
  }
}