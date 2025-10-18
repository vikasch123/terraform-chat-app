output "vpc_id" {
  description = "The ID of the VPC"
  value       = aws_vpc.django-chat-vpc.id
}

output "public_subnet_ids" {
  description = "List of public subnet IDs"
  value       = local.public_subnet_ids
}

output "private_subnet_ids" {
  description = "List of private subnet IDs"
  value       = local.private_subnet_ids
}

output "public_subnet_cidrs" {
  description = "List of public subnet CIDR's"
  value       = local.public_subnet_cidrs
}

output "private_subnet_cidrs" {
  description = "List of private subnet CIDR's"
  value       = local.private_subnet_cidrs
}

output "internet_gateway_id" {
  description = "The ID of the Internet Gateway"
  value       = aws_internet_gateway.django-chat-igw.id
}

output "nat_gateway_id" {
  description = "The ID of the NAT Gateway"
  value       = aws_nat_gateway.django-chat-nat.id
}

output "public_route_table_id" {
  description = "The ID of the public route table"
  value       = aws_route_table.django-chat-public-rt.id
}

output "private_route_table_id" {
  description = "The ID of the private route table"
  value       = aws_route_table.django-chat-private-rt.id
}
