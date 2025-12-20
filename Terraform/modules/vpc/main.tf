data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  azs = slice(data.aws_availability_zones.available.names, 0, 2)

  named_subnets = [
    { name = "Public-subnet-A", cidr_index = 0, type = "public", az = local.azs[0] },
    { name = "Public-subnet-B", cidr_index = 1, type = "public", az = local.azs[1] },

    { name = "App-subnet-A",    cidr_index = 2, type = "app",    az = local.azs[0] },
    { name = "App-subnet-B",    cidr_index = 3, type = "app",    az = local.azs[1] },

    { name = "DB-subnet-A",     cidr_index = 4, type = "db",     az = local.azs[0] },
    { name = "DB-subnet-B",     cidr_index = 5, type = "db",     az = local.azs[1] },
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
    if contains(["Public-subnet-A","Public-subnet-B"], k)
  }

  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}

# Create Elastic IPs for NAT Gateways
resource "aws_eip" "nat" {
  count = 2
  domain = "vpc"
  
  tags = merge(local.tags, { 
    Name = "${var.vpc_name}-nat-eip-${count.index + 1}"
  })
}

# Create NAT Gateways in public subnets
resource "aws_nat_gateway" "nat" {
  count = 2
  
  allocation_id = aws_eip.nat[count.index].id
  # Get the public subnet IDs and assign NAT Gateways to them
  subnet_id     = element([for k, s in aws_subnet.named : s.id if contains(["Public-subnet-A", "Public-subnet-B"], k)], count.index)
  
  tags = merge(local.tags, { 
    Name = "${var.vpc_name}-nat-gw-${count.index + 1}"
  })
  
  depends_on = [aws_internet_gateway.blog_igw]
}

####################################################
######### APP SUBNET ROUTE TABLES (WITH NAT) #######
####################################################

# Create route tables for App subnets WITH NAT Gateway access
resource "aws_route_table" "app_with_nat_az1" {
  vpc_id = aws_vpc.blog_vpc.id
  tags   = merge(local.tags, { 
    Name = "${var.vpc_name}-app-with-nat-rt-az1"
  })
}

resource "aws_route_table" "app_with_nat_az2" {
  vpc_id = aws_vpc.blog_vpc.id
  tags   = merge(local.tags, { 
    Name = "${var.vpc_name}-app-with-nat-rt-az2"
  })
}

# Add routes to NAT Gateways for App subnets
resource "aws_route" "app_az1_to_nat" {
  route_table_id         = aws_route_table.app_with_nat_az1.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat[0].id
}

resource "aws_route" "app_az2_to_nat" {
  route_table_id         = aws_route_table.app_with_nat_az2.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat[1].id
}

# Associate App subnets with NAT-enabled route tables
resource "aws_route_table_association" "app_assoc_with_nat_az1" {
  subnet_id      = aws_subnet.named["App-subnet-A"].id
  route_table_id = aws_route_table.app_with_nat_az1.id
}

resource "aws_route_table_association" "app_assoc_with_nat_az2" {
  subnet_id      = aws_subnet.named["App-subnet-B"].id
  route_table_id = aws_route_table.app_with_nat_az2.id
}

####################################################
######### DB SUBNET ROUTE TABLES (NO NAT) ##########
####################################################

# Create route tables for DB subnets WITHOUT NAT Gateway access
resource "aws_route_table" "db_no_nat_az1" {
  vpc_id = aws_vpc.blog_vpc.id
  tags   = merge(local.tags, { 
    Name = "${var.vpc_name}-db-no-nat-rt-az1"
  })
}

resource "aws_route_table" "db_no_nat_az2" {
  vpc_id = aws_vpc.blog_vpc.id
  tags   = merge(local.tags, { 
    Name = "${var.vpc_name}-db-no-nat-rt-az2"
  })
}

# DO NOT add any internet/NAT routes to DB route tables
# They remain isolated with only local VPC routes

# Associate DB subnets with isolated route tables (no NAT)
resource "aws_route_table_association" "db_assoc_no_nat_az1" {
  subnet_id      = aws_subnet.named["DB-subnet-A"].id
  route_table_id = aws_route_table.db_no_nat_az1.id
}

resource "aws_route_table_association" "db_assoc_no_nat_az2" {
  subnet_id      = aws_subnet.named["DB-subnet-B"].id
  route_table_id = aws_route_table.db_no_nat_az2.id
}