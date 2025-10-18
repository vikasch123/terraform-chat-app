# variable "vpc_id" {
#   description = "The VPC ID of the security groups"
#   type        = string
# }

# variable "public_subnet-ids" {
#   description = "List of public subnet ID's"
#   type        = list(string)
# }

# variable "private_subnet_ids" {
#   description = "List of private subnet ID's because sometimes we only need to limit internet traffic coming only from private subnet"
#   type        = list(string)
# }

# variable "allowed_ssh_cidr" {
#   description = "Allow only specific IP's for ssh"
#   type        = string
# }


variable "sg_config" {
  type = map(object({
    name               = string
    vpc_id             = string
    public_subnet_ids  = list(string)
    private_subnet_ids = list(string)
    allowed_ssh_cidr   = string
    ingress_rules = list(object({
      from_port       = number
      to_port         = number
      protocol        = string
      cidr_blocks     = list(string)
      security_groups = optional(list(string), [])
      description     = string
    }))
  }))
}
