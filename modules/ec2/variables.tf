variable "instances" {
  description = "Map of EC2 instance configs"
  type = map(object({
    ami_id                      = string
    instance_type               = string
    subnet_id                   = string
    sg_ids                      = optional(list(string), [])
    tags                        = map(string)
    associate_public_ip_address = optional(bool, false)
    key_name                    = optional(string, null)
  }))
}
