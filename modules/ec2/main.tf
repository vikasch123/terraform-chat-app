resource "aws_instance" "app" {
  for_each = var.instances

  ami                    = each.value.ami_id
  instance_type          = each.value.instance_type
  subnet_id              = each.value.subnet_id
  vpc_security_group_ids = each.value.sg_ids
  tags                   = each.value.tags
}
