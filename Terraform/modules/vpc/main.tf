data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  azs = slice(data.aws_availability_zones.available.names, 0, 3)

  named_subnets = [
    { name = "Public-subnet-A", cidr_index = 0, type = "public", az = local.azs[0] },
    { name = "Public-subnet-B", cidr_index = 1, type = "public", az = local.azs[1] },
    { name = "Public-subnet-C", cidr_index = 2, type = "public", az = local.azs[2] },

    { name = "App-subnet-A",    cidr_index = 3, type = "app",    az = local.azs[0] },
    { name = "App-subnet-B",    cidr_index = 4, type = "app",    az = local.azs[1] },
    { name = "App-subnet-C",    cidr_index = 5, type = "app",    az = local.azs[2] },

    { name = "DB-subnet-A",     cidr_index = 6, type = "db",     az = local.azs[0] },
    { name = "DB-subnet-B",     cidr_index = 7, type = "db",     az = local.azs[1] },
    { name = "DB-subnet-C",     cidr_index = 8, type = "db",     az = local.azs[2] },
  ]

  tags = {
    Project = var.Project
    Env     = var.Env
    Managed = "terraform"
  }
}

resource "aws_vpc" "blog_vpc" {
  cidr_block                       = var.vpc_cidr
  enable_dns_support               = true
  enable_dns_hostnames             = true
  assign_generated_ipv6_cidr_block = true

  tags = merge(local.tags, { Name = var.vpc_name })
}

resource "aws_internet_gateway" "blog_igw" {
  vpc_id = aws_vpc.blog_vpc.id
  tags   = merge(local.tags, { Name = var.igw_name })
}

resource "aws_subnet" "named" {
  for_each = { for s in local.named_subnets : s.name => s }

  vpc_id                          = aws_vpc.blog_vpc.id
  cidr_block                      = cidrsubnet(var.vpc_cidr, 4, each.value.cidr_index)
  availability_zone               = each.value.az

  # use an offset to avoid colliding with existing IPv6 /64s
  ipv6_cidr_block                 = cidrsubnet(aws_vpc.blog_vpc.ipv6_cidr_block, 8, each.value.cidr_index + var.ipv6_index_offset)
  assign_ipv6_address_on_creation = true

  map_public_ip_on_launch = each.value.type == "public" ? true : false

  tags = merge(local.tags, { Name = each.key, Role = each.value.type })
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.blog_vpc.id
  tags   = merge(local.tags, { Name = "${var.vpc_name}-public-rt" })
}

resource "aws_route" "public_ipv4_default" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.blog_igw.id
}

resource "aws_route" "public_ipv6_default" {
  route_table_id               = aws_route_table.public.id
  destination_ipv6_cidr_block  = "::/0"
  gateway_id                   = aws_internet_gateway.blog_igw.id
}

resource "aws_route_table_association" "public_assoc" {
  for_each = {
    for k, s in aws_subnet.named :
    k => s
    if contains(["Public-subnet-A","Public-subnet-B","Public-subnet-C"], k)
  }

  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}




####################################################
######### PRIVATE ROUTE TABLE ######################
####################################################

# Create a route table for private subnets (App and DB)
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.blog_vpc.id
  tags   = merge(local.tags, { Name = "${var.vpc_name}-private-rt" })
}

# Associate App subnets with private route table
resource "aws_route_table_association" "app_assoc" {
  for_each = {
    for k, s in aws_subnet.named :
    k => s
    if contains(["App-subnet-A", "App-subnet-B", "App-subnet-C"], k)
  }

  subnet_id      = each.value.id
  route_table_id = aws_route_table.private.id
}

# Associate DB subnets with private route table
resource "aws_route_table_association" "db_assoc" {
  for_each = {
    for k, s in aws_subnet.named :
    k => s
    if contains(["DB-subnet-A", "DB-subnet-B", "DB-subnet-C"], k)
  }

  subnet_id      = each.value.id
  route_table_id = aws_route_table.private.id
}
