# Get the latest Ubuntu 22.04 AMI automatically
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}

# Create one EC2 instance per web server (using count)
resource "aws_instance" "web_server" {
  count         = var.web_server_count
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.micro"
  vpc_security_group_ids = [aws_security_group.web_server.id]

  user_data = <<-EOF
    #!/bin/bash
    apt-get update -y
    apt-get install -y nginx
    echo "<h1>Hello from web-server-${count.index + 1}</h1>" > /var/www/html/index.html
    systemctl start nginx
    systemctl enable nginx
  EOF

  tags = {
    Name = "web-server-${count.index + 1}"
  }
}
