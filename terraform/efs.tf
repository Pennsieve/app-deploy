// EFS filesystem
resource "aws_efs_file_system" "pipeline" {
  creation_token = "efs-${random_uuid.val.id}"
  encrypted = true
  availability_zone_name = "us-east-1a" # do we need this?

  tags = {
    Name = "efs-${random_uuid.val.id}"
  }
}

// mount target(s)
resource "aws_efs_mount_target" "mnt" {
  file_system_id = aws_efs_file_system.pipeline.id
  subnet_id      = aws_subnet.subnet_private.id
  security_groups = [aws_default_security_group.default.id]
}

# EFS access point used by post processor
resource "aws_efs_access_point" "access_point_for_post_lambda" {
  file_system_id = aws_efs_file_system.pipeline.id

  root_directory {
    path = "/efs/output"
    creation_info {
      owner_gid   = 1000
      owner_uid   = 1000
      permissions = "777"
    }
  }

  posix_user {
    gid = 1000
    uid = 1000
  }
}