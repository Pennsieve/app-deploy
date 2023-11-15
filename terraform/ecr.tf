resource "aws_ecr_repository" "app" {
  name                 = "${var.app_repository}-${random_uuid.val.id}"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = false # consider inplications of setting to true
  }
}