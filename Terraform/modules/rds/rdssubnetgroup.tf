resource "aws_db_subnet_group" "blog" {
  name        = "blog-rds-sub-group"
  description = "subnets for rds instance"
  subnet_ids  = var.db_subnet_ids

}
