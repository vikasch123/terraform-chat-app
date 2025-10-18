output "security_group_ids" {
  description = "Map of security group names to their IDs"
  value       = { for k, sg in aws_security_group.chat-vpc-sgs : k => sg.id }
}
