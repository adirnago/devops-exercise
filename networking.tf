# Get the default VPC
data "aws_vpc" "default" {
  default = true
}

# Security group for web servers
resource "aws_security_group" "web_server" {
  name        = "web-server-sg"
  description = "Allow HTTP traffic to web servers"
  vpc_id      = data.aws_vpc.default.id

  # Allow HTTP from anywhere
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "web-server-sg"
  }
}
