output "web_server_public_ips" {
  description = "Public IPs of all web servers"
  value       = aws_instance.web_server[*].public_ip
}

output "cloudfront_url" {
  description = "CloudFront Distribution URL"
  value       = "https://${aws_cloudfront_distribution.main.domain_name}"
}
