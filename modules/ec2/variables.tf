variable "instances" {
  description = "Map of EC2 instance configs"
  type = map(object({
    ami_id        = string
    instance_type = string
    subnet_id     = string
    sg_ids        = optional(list(string), [])
    tags          = map(string)
  }))
}
