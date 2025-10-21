variable "security_groups" {
  description = "Map of security groups with their configurations"
  type = map(object({
    description = string
    vpc_id      = string
    ingress_rules = list(object({
      from_port       = number
      to_port         = number
      protocol        = string
      cidr_blocks     = optional(list(string), [])
      security_groups = optional(list(string), [])
      description     = optional(string, "")
    }))


  }))
}
