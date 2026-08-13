# Load Balancer
resource "aws_lb" "main" {
  name               = "devops-exercise-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.web_server.id]
  subnets            = data.aws_subnets.default.ids

  tags = {
    Name = "devops-exercise-alb"
    Version = var.load_balancer_version
  }
}

# Target Group (the web servers)
resource "aws_lb_target_group" "web_servers" {
  name     = "devops-exercise-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.default.id

  # Round-robin is the default algorithm
  load_balancing_algorithm_type = "round_robin"

  health_check {
    enabled  = true
    path     = "/health"
    port     = "traffic-port"
    protocol = "HTTP"
    matcher  = "200"
  }

  tags = {
    Name = "devops-exercise-tg"
  }
}

# Register web servers in the target group
resource "aws_lb_target_group_attachment" "web_servers" {
  count            = var.web_server_count
  target_group_arn = aws_lb_target_group.web_servers.arn
  target_id        = aws_instance.web_server[count.index].id
  port             = 80
}

# Listener - listens on port 80 and forwards to target group
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web_servers.arn
  }
}
# Health endpoint on the load balancer

resource "aws_lb_listener_rule" "health" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 1

  action {
    type = "fixed-response"

    fixed_response {
      content_type = "application/json"
      message_body = "{\"status\":\"healthy\",\"component\":\"load-balancer\",\"version\":\"${var.load_balancer_version}\"}"
      status_code  = "200"
    }
  }

  condition {
    path_pattern {
      values = ["/health"]
    }
  }
}
