// ## App ##
resource "aws_iam_role" "task_role_for_app" { #
  name               = "task_role_for_app-${random_uuid.val.id}"
  assume_role_policy = data.aws_iam_policy_document.app_role_assume_role.json
  managed_policy_arns = [aws_iam_policy.app_efs_policy.arn]
}

# resource should be specific EFS ID
resource "aws_iam_policy" "app_efs_policy" { #
  name = "app_role_efs_policy-${random_uuid.val.id}"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "elasticfilesystem:ClientMount",
          "elasticfilesystem:ClientWrite",
          "elasticfilesystem:ClientRootAccess"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}

data "aws_iam_policy_document" "app_role_assume_role" { #
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

// ECS Task Execution IAM role
resource "aws_iam_role" "execution_role_for_app" { #
  name               = "execution_role_for_app-${random_uuid.val.id}"
  assume_role_policy = data.aws_iam_policy_document.app_execution_role_assume_role.json
  managed_policy_arns = [aws_iam_policy.app_execution_role_policy.arn]
}

resource "aws_iam_policy" "app_execution_role_policy" { #
  name = "app_task_execution_role_policy-${random_uuid.val.id}"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:CreateLogGroup"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}

data "aws_iam_policy_document" "app_execution_role_assume_role" { #
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}