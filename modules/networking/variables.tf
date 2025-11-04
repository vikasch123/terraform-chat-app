variable "aws_region" {
  type    = string
  default = "us-east-1"
  validation {
    condition     = length(var.aws_region) > 0
    error_message = "The AWS region must not be empty."
  }
}

variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
  validation {
    condition     = can(cidrnetmask(var.vpc_cidr))
    error_message = "The VPC CIDR block must be a valid CIDR notation."
  }
}

variable "vpc_name" {
  type    = string
  default = "django-chat-vpc"
  validation {
    condition     = length(var.vpc_name) > 0
    error_message = "The VPC must have a non-empty name."
  }
}
# local {
#}
# ${local.project_name}


# subnet 1 ->  cidr_block az, name, is_public
# subnet 2 -> key-> subnets name , value -> object {      key->value 
#cidr_}
variable "subnet_config" {
  type = map(object({
    cidr_block        = string
    availability_zone = string
    name              = string
    is_public         = optional(bool, false)
  }))
}


variable "igw_name" {

}


variable "public_rt_name" {}
