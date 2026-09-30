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