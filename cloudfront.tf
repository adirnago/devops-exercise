resource "aws_cloudfront_distribution" "main" {
  enabled             = true
  comment             = "${var.cluster_name} CloudFront Distribution"
  default_root_object = "index.html"

  # המקור — ה־ALB שלנו
  origin {
    domain_name = aws_lb.main.dns_name
    origin_id   = "${var.cluster_name}-alb"

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  # הגדרות Cache ברירת מחדל
  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "${var.cluster_name}-alb"
    viewer_protocol_policy = "allow-all"

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    # TTL — כמה זמן התוכן נשמר ב־cache (בשניות)
    min_ttl     = 0
    default_ttl = 30
    max_ttl     = 300
  }

  # Cache behavior מיוחד ל־/health — אסור לשמור ב־cache!
  ordered_cache_behavior {
    path_pattern           = "/health"
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "${var.cluster_name}-alb"
    viewer_protocol_policy = "allow-all"

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    # TTL = 0 אומר אל תשמור ב־cache בכלל
    min_ttl     = 0
    default_ttl = 0
    max_ttl     = 0
  }

  # הגבלות גיאוגרפיות — none = פתוח לכולם
  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  # SSL Certificate
  viewer_certificate {
    cloudfront_default_certificate = true
  }

  tags = {
    Name    = "${var.cluster_name}-cf"
    Version = var.load_balancer_version
  }
}
