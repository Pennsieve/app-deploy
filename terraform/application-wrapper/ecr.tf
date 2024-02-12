resource "aws_ecr_repository" "app" {
  name                 = "${var.app_name}-${random_uuid.val.id}"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = false # consider implications of setting to true
  }
}