output "instance_ids" {
  description = "Map of instance names to their IDs"
  value       = { for k, inst in aws_instance.app : k => inst.id }
}

output "instance_public_ips" {
  description = "Map of instance names to their public IPs"
  value       = { for k, inst in aws_instance.app : k => inst.public_ip }
}

output "instance_private_ips" {
  description = "Map of instance names to their private IPs"
  value       = { for k, inst in aws_instance.app : k => inst.private_ip }
}
