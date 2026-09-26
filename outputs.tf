output "vpc_id" {
  description = "ID of the VPC created by Terraform"
  value       = aws_vpc.main.id
}