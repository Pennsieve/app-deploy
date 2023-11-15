resource "aws_ecr_repository" "app" {
  name                 = "${var.app_repository}-${random_uuid.val.id}"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = false # consider implications of setting to true
  }
}

resource "aws_ecr_repository" "post-processor" {
  name                 = "${var.post_processor_repository}-${random_uuid.val.id}"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = false # consider implications of setting to true
  }
}