# modules/rds/main.tf
resource "aws_db_instance" "blogrds" {
  identifier                  = "blogrds"
  engine                      = "mysql"
  engine_version              = var.db_engine_version
  instance_class              = var.db_instance_class
  allocated_storage           = var.db_allocated_storage
  storage_type                = "gp2"
  
  # 🛠️ FIX: Use 'db_name' to create the initial database (which is "wordpressblogdb")
  db_name                     = var.DBName  # This is the correct attribute for the initial database
  
  username                    = var.DBUser
  password                    = var.DBPassword
  db_subnet_group_name        = aws_db_subnet_group.blog.name 
  vpc_security_group_ids      = [var.rds_sg_id]
  skip_final_snapshot         = true
  publicly_accessible         = false
  multi_az                    = false
  backup_retention_period     = 7
  deletion_protection         = false
  apply_immediately           = true
  auto_minor_version_upgrade  = true
}