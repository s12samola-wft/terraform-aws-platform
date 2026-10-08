# Look up the newest Amazon Linux 2023 AMI (the house plan)
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }
}

# The front door lock for our web server
resource "aws_security_group" "web" {
  name        = "web-sg"
  description = "Allow HTTP in, all traffic out"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "web-sg"
  }
}

# Inbound rule: anyone may use the front door (port 80, HTTP)
resource "aws_vpc_security_group_ingress_rule" "http_in" {
  security_group_id = aws_security_group.web.id
  description       = "HTTP from anywhere"
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
}

# Outbound rule: the server may go out anywhere (e.g. to download nginx)
resource "aws_vpc_security_group_egress_rule" "all_out" {
  security_group_id = aws_security_group.web.id
  description       = "Allow all outbound"
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

# The web server (the house)
resource "aws_instance" "web" {
  ami                         = data.aws_ami.amazon_linux.id
  instance_type               = "t3.micro"
  subnet_id                   = aws_subnet.public_a.id
  vpc_security_group_ids      = [aws_security_group.web.id]
  iam_instance_profile        = aws_iam_instance_profile.web.name
  associate_public_ip_address = true
  # Require IMDSv2: the info desk needs a session token (PIN)
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  # Encrypt the server's disk
  root_block_device {
    encrypted   = true
    volume_type = "gp3"
  }

  # The move-in checklist: runs once, on first boot
  user_data = <<-EOF
    #!/bin/bash
    dnf install -y nginx
    echo "<h1>Hello from Samson's Terraform-built server</h1>" > /usr/share/nginx/html/index.html
    systemctl enable --now nginx
  EOF

  user_data_replace_on_change = true

  lifecycle {
    ignore_changes = [ami]
  }

  tags = {
    Name = "web-server"
  }
}
