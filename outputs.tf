output "vpc_id" {
  description = "ID of the VPC created by Terraform"
  value       = aws_vpc.main.id
}
output "public_subnet_ids" {
  value = [aws_subnet.public_a.id, aws_subnet.public_b.id]
}

output "private_subnet_ids" {
  value = [aws_subnet.private_a.id, aws_subnet.private_b.id]
}
# The web server (the house)
resource "aws_instance" "web" {
  ami                         = data.aws_ami.amazon_linux.id
  instance_type               = "t3.micro"
  subnet_id                   = aws_subnet.public_a.id
  vpc_security_group_ids      = [aws_security_group.web.id]
  associate_public_ip_address = true

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
output "web_public_ip" {
  value = aws_instance.web.public_ip
}

output "web_url" {
  value = "http://${aws_instance.web.public_ip}"
}