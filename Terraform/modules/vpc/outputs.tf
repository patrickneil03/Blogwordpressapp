output "named_subnet_ids" {
  value = { for k, s in aws_subnet.named : k => s.id }
}

output "named_subnet_cidrs" {
  value = { for k, s in aws_subnet.named : k => s.cidr_block }
}

output "named_subnet_ipv6" {
  value = { for k, s in aws_subnet.named : k => s.ipv6_cidr_block }
}

output "vpc_id" {
  value = aws_vpc.blog_vpc.id
  
}

output "db_subnet_ids" {
  description = "List of DB subnet IDs for RDS (DB-subnet-A, DB-subnet-B, DB-subnet-C)"
  value = [
    aws_subnet.named["DB-subnet-A"].id,
    aws_subnet.named["DB-subnet-B"].id,
    aws_subnet.named["DB-subnet-C"].id,
  ]
}


output "app_subnet_ids" {
  description = "A map of App Subnet IDs keyed by their name."
  value = {
    for k, s in aws_subnet.named :
    k => s.id
    if s.tags.Role == "app" # Filters for subnets tagged as 'app'
  }
}

output "pub_subnet_ids" {
  description = "List of public subnet IDs for public facing ec2 (Public-subnet-A, Public-subnet-B, Public-subnet-C)"
  value = [
    aws_subnet.named["Public-subnet-A"].id,
    aws_subnet.named["Public-subnet-B"].id,
    aws_subnet.named["Public-subnet-C"].id,
  ]
}