module "vpc_module" {
  source         = "./modules/networking"
  aws_region     = "us-east-1"
  vpc_cidr       = "10.0.0.0/16"
  vpc_name       = "django-chat-vpc"
  public_rt_name = "django-chat-public-rt"
  igw_name       = "django-chat-igw"
  subnet_config = {
    "django-chat-public-subnet-1" = {
      cidr_block        = "10.0.0.0/24"
      availability_zone = "us-east-1a"
      name              = "django-chat-public-subnet-1"
      is_public         = true
    }

    "django-chat-private-subnet-1" = {
      cidr_block        = "10.0.1.0/24"
      availability_zone = "us-east-1a"
      name              = "django-chat-private-subnet-1"
      is_public         = false
    }

    "django-chat-public-subnet-2" = {
      cidr_block        = "10.0.2.0/24"
      availability_zone = "us-east-1b"
      name              = "django-chat-public-subnet-2"
      is_public         = true
    }

    "django-chat-private-subnet-2" = {
      cidr_block        = "10.0.3.0/24"
      availability_zone = "us-east-1b"
      name              = "django-chat-private-subnet-2"
      is_public         = false
    }

  }

}


# calling the ec2 module to spin-up our ec2 instances in the infra

module "ec2" {
  source = "./modules/ec2"
  instances = {
    "web" = {
      ami_id        = "	ami-05338380e819c8869"
      instance_type = "t3.micro"
      subnet_id     = module.vpc_module.public_subnet_ids[0]
      sg_ids        = [module.sg-module.security_group_ids["web-nginx-sg"]]
      tags          = { Name = "web-nginx" }
    }

    "app" = {
      ami_id        = "ami-054735a0b4055fdf9"
      instance_type = "t3.micro"
      subnet_id     = module.vpc_module.private_subnet_ids[0]
      # sg_ids        = [module.sg-module.security_group_ids["django-app-sg"]]
      tags = {
        Name = "django-app"
      }
    }

    "db" = {
      ami_id        = "ami-0eb67d30053311bfc"
      instance_type = "t3.micro"
      subnet_id     = module.vpc_module.private_subnet_ids[1]
      # sg_ids        = [module.sg-module.security_group_ids["mysql-db-sg"]]
      tags = {
        Name = "mysql-db"
      }
    }
  }
}

module "sg-module" {
  source = "./modules/security-group"
  sg_config = {
    "web-nginx-sg" = {
      name               = "web-nginx-sg"
      vpc_id             = module.vpc_module.vpc_id
      public_subnet_ids  = module.vpc_module.public_subnet_ids
      private_subnet_ids = module.vpc_module.private_subnet_ids
      allowed_ssh_cidr   = "0.0.0.0/0"
      ingress_rules = [
        {
          from_port   = 80
          to_port     = 80
          protocol    = "tcp"
          cidr_blocks = ["0.0.0.0/0"]
          description = "allow tcp"
        },

        {
          from_port   = 22
          to_port     = 22
          protocol    = "tcp"
          cidr_blocks = ["0.0.0.0/0"]
          description = "Allow ssh"

        }
      ]
    }
  }
}

# module "sg-db" {
#   source = "./modules/security_group"
#   sg_config = {
#     "mysql-db-sg" = {
#       name   = "mysql-db-sg"
#       vpc_id = module.vpc_module.vpc_id
#       ingress_rules = [
#         {
#           from_port       = 22
#           to_port         = 22
#           protocol        = "tcp"
#           security_groups = [module.sg-web.security_group_ids["web-nginx-sg"]]
#         }
#       ]
#     }
#   }
# }



# module "sg-app" {
#   source = "./modules/security_group"
#   sg_config = {
#     "django-app-sg" = {
#       name   = "django-app-sg"
#       vpc_id = module.vpc_module.vpc_id
#       ingress_rules = [
#         {
#           from_port   = 8000
#           to_port     = 8000
#           protocol    = "tcp"
#           cidr_blocks = module.vpc_module.private_subnet_cidrs
#           description = "Allow Django app traffic"
#         },
#         {
#           from_port       = 22
#           to_port         = 22
#           protocol        = "tcp"
#           security_groups = [module.sg-web.security_group_ids["web-nginx-sg"]]
#           description     = "Allow SSH from web server SG"
#         }
#       ]
#     }
#   }
# }



#       "django-app-sg" = {
#         name               = "django-app-sg"
#         vpc_id             = module.vpc_module.vpc_id
#         public_subnet_ids  = module.vpc_module.public_subnet_ids
#         private_subnet_ids = module.vpc_module.private_subnet_ids
#         allowed_ssh_cidr   = "0.0.0.0/0"
#         ingress_rules = [
#           {
#             from_port       = 8000
#             to_port         = 8000
#             protocol        = "tcp"
#             cidr_blocks     = module.vpc_module.private_subnet_cidrs
#             security_groups = [module.sg-module.security_group_ids["web-server-nginx"]]
#             description     = "allow only port 8000 only from private subnets within the vpc"
#           }
#         ]
#       }

#       "mysql-db-sg" = {
#         name   = "mysql-db-sg"
#         vpc_id = module.vpc_module.vpc_id
#         ingress_rules = [
#           {
#             from_port       = 3306
#             to_port         = 3306
#             protocol        = "tcp"
#             security_groups = [module.sg-module.security_group_ids["web-server-nginx"]]
#             description     = "to only allow traffic on port 3306 through web-server-nginx-sg"

#           },
#           {
#             from_port       = 22
#             to_port         = 22
#             protocol        = "tcp"
#             security_groups = [module.sg-module.security_group_ids["web-server-nginx"]]
#             description     = "to  allow ssh  through web-server-nginx-sg"

#           }
#         ]
#       }

#     }

#   }
# }

