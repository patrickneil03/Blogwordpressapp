resource "aws_lb" "blogwordpressALB" {
  name               = "blogwordpressalb"
  internal           = false
  load_balancer_type = "application"
  ip_address_type    = "ipv4"
  security_groups    = [aws_security_group.load_balancer.id]
  subnets            = var.pub_subnet_ids

  enable_deletion_protection = false

  tags = {
    Name = "blogwordpressALB"
  }
}

# HTTPS listener (main) with your specific certificate
resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.blogwordpressALB.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = "arn:aws:acm:ap-southeast-1:516969219217:certificate/40f576b6-3df0-4e31-82b2-79e9a3e2c9a5"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.blog_asg_tg.arn
  }
}

# HTTP listener that redirects to HTTPS
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.blogwordpressALB.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "redirect"
    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}