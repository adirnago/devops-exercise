output "web_server_public_ips" {
  description = "Public IPs of all web servers"
  value       = aws_instance.web_server[*].public_ip
}
