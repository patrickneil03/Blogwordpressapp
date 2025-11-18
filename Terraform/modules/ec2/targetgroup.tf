resource "aws_lb_target_group" "blog_asg_tg" {
  name        = "blog-asg-tg"
  target_type = "instance"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  ip_address_type = "ipv4"

  # CRITICAL: Enable stickiness to maintain sessions
  stickiness {
    enabled = true
    type    = "lb_cookie"
    cookie_duration = 86400
  }

  health_check {
    protocol            = "HTTP"
    path                = "/"
    matcher             = "200-399"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  tags = {
    Name = "blog-asg-tg"
  }
}