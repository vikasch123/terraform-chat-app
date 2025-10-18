resource "aws_vpc" "django-chat-vpc" {
  cidr_block = var.vpc_cidr
  tags = {
    Name = var.vpc_name
  }
}


resource "aws_subnet" "django-chat-subnets" {
  vpc_id            = aws_vpc.django-chat-vpc.id
  for_each          = var.subnet_config
  cidr_block        = each.value.cidr_block
  availability_zone = each.value.availability_zone
  tags = {
    name = each.key
  }
}

resource "aws_internet_gateway" "django-chat-igw" {
  vpc_id = aws_vpc.django-chat-vpc.id
  tags = {
    Name = var.igw_name
  }
}


locals {
  public_subnet_ids = [
    for key, subnet in aws_subnet.django-chat-subnets : subnet.id if lookup(var.subnet_config[key], "is_public", false)
  ]
}

locals {
  private_subnet_ids = [
    for key, subnet in aws_subnet.django-chat-subnets : subnet.id if !lookup(var.subnet_config[key], "is_public", false)
  ]
}

locals {
  public_subnet_cidrs = [
    for key, subnet in aws_subnet.django-chat-subnets : subnet.cidr_block if lookup(var.subnet_config[key], "is_public", false)
  ]
}

locals {
  private_subnet_cidrs = [
    for key, subnet in aws_subnet.django-chat-subnets : subnet.cidr_block if !lookup(var.subnet_config[key], "is_public", false)
  ]
}

resource "aws_nat_gateway" "django-chat-nat" {
  subnet_id = local.private_subnet_ids[0]
}

resource "aws_route_table" "django-chat-public-rt" {
  vpc_id = aws_vpc.django-chat-vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.django-chat-igw.id
  }
  tags = {
    Name = var.public_rt_name
  }
}


# resource "aws_route_table_association" "django-chat-public-rt-assoc" {
#   for_each       = toset(local.public_subnet_ids)
#   subnet_id      = each.value
#   route_table_id = aws_route_table.django-chat-public-rt.id
# }

resource "aws_route_table" "django-chat-private-rt" {
  vpc_id = aws_vpc.django-chat-vpc.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.django-chat-nat.id
  }
}

# resource "aws_route_table_association" "django-chat-private-rt-assoc" {
#   for_each       = toset(local.private_subnet_ids)
#   subnet_id      = each.value
#   route_table_id = aws_route_table.django-chat-private-rt
# }



resource "aws_route_table_association" "django-chat-public-rt-assoc" {
  for_each       = { for key, subnet in aws_subnet.django-chat-subnets : key => subnet if lookup(var.subnet_config[key], "is_public", false) }
  subnet_id      = each.value.id
  route_table_id = aws_route_table.django-chat-public-rt.id
}

resource "aws_route_table_association" "django-chat-private-rt-assoc" {
  for_each       = { for key, subnet in aws_subnet.django-chat-subnets : key => subnet if !lookup(var.subnet_config[key], "is_public", false) }
  subnet_id      = each.value.id
  route_table_id = aws_route_table.django-chat-private-rt.id
}
