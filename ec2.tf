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