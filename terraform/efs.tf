// EFS filesystem
resource "aws_efs_file_system" "pipeline" {
  creation_token = "efs-${random_uuid.val.id}"
  encrypted = true

  tags = {
    Name = "efs-${random_uuid.val.id}"
  }
}

// mount target(s)
resource "aws_efs_mount_target" "mnt" {
  file_system_id = aws_efs_file_system.pipeline.id
  subnet_id      = split(",", local.subnet_ids)[count.index]
  security_groups = [aws_default_security_group.default.id]
  count = 6
}
