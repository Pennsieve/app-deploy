resource "aws_ecr_repository" "app" {
  name                 = "${var.app_repository}-${random_uuid.val.id}"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = false # consider implications of setting to true
  }
}

resource "aws_ecr_repository" "pre-processor" {
  name                 = "${var.pre_processor_repository}-${random_uuid.val.id}"
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

resource "aws_ecr_repository" "workflow-manager" {
  name                 = "${var.workflow_manager_repository}-${random_uuid.val.id}"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = false # consider implications of setting to true
  }
}