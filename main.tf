provider "aws" {
  region = "eu-central-1"
}

# Security Group
resource "aws_security_group" "web_sg" {
  name = "web-sg-terraform"  # <- zmieniona nazwa, musi być unikalna w VPC
  description = "Allow HTTP and SSH"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Pobranie najnowszego Ubuntu 22.04
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}

# EC2 Instance
resource "aws_instance" "web" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = "t3.micro"
  key_name                    = "my_aws_key"   # <- dokładnie nazwa Key Pair w AWS
  vpc_security_group_ids      = [aws_security_group.web_sg.id]
  associate_public_ip_address = true            # <- konieczne dla SSH z internetu

  user_data = <<-EOF
              #!/bin/bash
              apt update -y
              apt install -y nginx
              systemctl start nginx
              systemctl enable nginx
              echo "<h1>Hello from Terraform 🚀</h1>" > /var/www/html/index.html
              EOF

  tags = {
    Name = "terraform-web-server"
  }
}