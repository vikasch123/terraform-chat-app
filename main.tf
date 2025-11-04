
# This module orchestrates the creation of a multi-tier web application:
# - VPC with public and private subnets across multiple AZs
# - Web server (Nginx) in public subnet acting as bastion host
# - App server (Django) in private subnet
# - Database server (MySQL) in private subnet
# - Security groups with least-privilege access
# - Auto-generated Ansible inventory for configuration management
#
# Network Architecture:
# - Public subnets: 10.0.0.0/24, 10.0.2.0/24 (for web/load balancers)
# - Private subnets: 10.0.1.0/24, 10.0.3.0/24 (for app/database)
# - Web server acts as SSH proxy/bastion for private instances

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



# SSH Key Pairs for EC2 Instances

# Generate RSA key pairs for secure SSH access to EC2 instances

# Allocate Elastic IP for web server (Nginx/bastion)
resource "aws_eip" "web_ip" {
  instance = module.ec2.instance_ids["web"]
}

# Web server SSH key pair
resource "tls_private_key" "web-key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "web-keypair" {
  key_name   = "web-key"
  public_key = tls_private_key.web-key.public_key_openssh
}

# App server SSH key pair
resource "tls_private_key" "app-key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "app-keypair" {
  key_name   = "app-key"
  public_key = tls_private_key.app-key.public_key_openssh
}

# Database server SSH key pair
resource "tls_private_key" "db-key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "db-keypair" {
  key_name   = "db-key"
  public_key = tls_private_key.db-key.public_key_openssh
}

# Save private keys to local files for SSH access
resource "local_file" "web_key_file" {
  content  = tls_private_key.web-key.private_key_pem
  filename = "web.pem"
  file_permission = "0600"
}

resource "local_file" "app_key_file" {
  content  = tls_private_key.app-key.private_key_pem
  filename = "app.pem"
  file_permission = "0600"
}

resource "local_file" "db_key_file" {
  content  = tls_private_key.db-key.private_key_pem
  filename = "db.pem"
  file_permission = "0600"
}

# =============================================================================
# EC2 Instances Configuration
# =============================================================================
module "ec2" {
  source = "./modules/ec2"
  instances = {
    # Web server (Nginx) - public subnet with Elastic IP
    # Acts as bastion host for SSH access to private instances
    "web" = {
      ami_id                      = "ami-05338380e819c8869"
      instance_type               = "t3.micro"
      subnet_id                   = module.vpc_module.public_subnet_ids[0]
      sg_ids                      = [module.sg-module.security_group_ids["web"]]
      tags                        = { Name = "web-nginx" }
      associate_public_ip_address = true
      key_name                    = aws_key_pair.web-keypair.key_name
    }

    # App server (Django) - private subnet, accessed via web server
    "app" = {
      ami_id        = "ami-054735a0b4055fdf9"
      instance_type = "t3.micro"
      subnet_id     = module.vpc_module.private_subnet_ids[0]
      sg_ids        = [module.sg-module.security_group_ids["app"]]
      tags = {
        Name = "django-app"
      }
      key_name = aws_key_pair.app-keypair.key_name
    }

    # Database server (MySQL) - private subnet, accessed via web server
    "db" = {
      ami_id        = "ami-0eb67d30053311bfc"
      instance_type = "t3.micro"
      subnet_id     = module.vpc_module.private_subnet_ids[1]
      sg_ids        = [module.sg-module.security_group_ids["db"]]
      tags = {
        Name = "mysql-db"
      }
      key_name = aws_key_pair.db-keypair.key_name
    }
  }
}

# =============================================================================
# Security Groups Configuration
# =============================================================================
module "sg-module" {
  source = "./modules/security-group"
  security_groups = {
    web = {
      description = "Web SG"
      vpc_id      = module.vpc_module.vpc_id
      ingress_rules = [
        { from_port = 80, to_port = 80, protocol = "tcp", cidr_blocks = ["0.0.0.0/0"] }
      ]
    }

    db = {
      description = "db-sg"
      vpc_id      = module.vpc_module.vpc_id
      ingress_rules = [
        { from_port = 3306, to_port = 3306, protocol = "tcp" }
      ]
    }

    app = {
      description = "App SG"
      vpc_id      = module.vpc_module.vpc_id
      ingress_rules = [
        { from_port = 8000, to_port = 8000, protocol = "tcp", cidr_blocks = ["10.0.0.0/16"], description = "Allow Django app traffic" }
      ]

    }
  }
}




# =============================================================================
# Additional Security Group Rules for SSH Proxy Access
# =============================================================================
# Enable SSH access from web server (bastion) to private instances

resource "aws_security_group_rule" "app_ssh_from_web" {
  type                     = "ingress"
  from_port                = 22
  to_port                  = 22
  protocol                 = "tcp"
  security_group_id        = module.sg-module.security_group_ids["app"]
  source_security_group_id = module.sg-module.security_group_ids["web"]
  description              = "Allow SSH from web to app"
}

resource "aws_security_group_rule" "db_ssh_from_web" {
  type                     = "ingress"
  from_port                = 22
  to_port                  = 22
  protocol                 = "tcp"
  security_group_id        = module.sg-module.security_group_ids["db"]
  source_security_group_id = module.sg-module.security_group_ids["web"]
  description              = "Allow SSH from web to db"
}

# Generate Ansible inventory file dynamically from module outputs
resource "local_file" "ansible_inventory" {
  content = templatefile("${path.module}/inventory.tmpl", {
    # Web server configuration - public IP with direct access
    web_public_ip = module.ec2.instance_public_ips["web"]
    # Use abspath() to make key paths absolute, allowing inventory to work from any directory
    web_key_path  = abspath(local_file.web_key_file.filename)

    # App server configuration - private IP accessed via bastion (web server)
    app_private_ip = module.ec2.instance_private_ips["app"]
    app_key_path   = abspath(local_file.app_key_file.filename)

    # Database server configuration - private IP accessed via bastion (web server)
    db_private_ip = module.ec2.instance_private_ips["db"]
    db_key_path   = abspath(local_file.db_key_file.filename)
  })
  filename        = "${path.module}/inventory.yaml"
  file_permission = "0644"

  # Ensure this runs after all resources are created
  depends_on = [
    module.ec2,
    local_file.web_key_file,
    local_file.app_key_file,
    local_file.db_key_file
  ]
}


