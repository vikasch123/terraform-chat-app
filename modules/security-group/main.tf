resource "aws_security_group" "chat-vpc-sgs" {
  for_each = var.sg_config
  vpc_id   = each.value.vpc_id
  name     = each.value.name
  dynamic "ingress" {
    for_each = each.value.ingress_rules
    content {
      from_port       = ingress.value.from_port
      to_port         = ingress.value.to_port
      protocol        = ingress.value.protocol
      cidr_blocks     = ingress.value.cidr_blocks
      security_groups = lookup(ingress.value, "security_groups", [])
      description     = ingress.value.description
    }

  }
}
