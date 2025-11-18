
locals {
    tags = {
        Project = var.Project
        Env     = var.Env
        Managed = "terraform"
    }
}

resource "aws_efs_file_system" "blog_efs" {
  
  tags = merge(local.tags, {
    Name = "blog-efs"
  })
  
  # 4. Encryption = false (default, but specified here)
  encrypted = false

  # 3. Lifecycle management: Transition into Infrequent Access (IA) 30 days
  lifecycle_policy {
    transition_to_ia = "AFTER_30_DAYS"
    # Transition to archive is omitted as requested
  }
}


resource "aws_efs_mount_target" "blog_mount_targets" {
  # FIX: We now expect var.app_subnet_ids to be a map<string, string> (Subnet Name => Subnet ID).
  # This simplifies the logic and aligns with the typical output structure of VPC modules.
  for_each = var.app_subnet_ids

  file_system_id  = aws_efs_file_system.blog_efs.id
  
  # The subnet ID is now the value of the map entry (each.value)
  subnet_id       = each.value 
  
  # Attach the EFS security group created in this module
  security_groups = [var.efs_sg_id]
}


resource "aws_efs_backup_policy" "blog_efs_backup_policy" {
  file_system_id = aws_efs_file_system.blog_efs.id
  backup_policy {
    status = "ENABLED"
  }
}