output "instance_ids" {
  value = { for k, inst in aws_instance.app : k => inst.id }
}
