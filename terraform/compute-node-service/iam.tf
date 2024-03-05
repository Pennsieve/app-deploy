// ECS task IAM role
resource "aws_iam_role" "task_role_for_ecs_task" {
  name               = "task_role_for_ecs_task-${random_uuid.val.id}"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_role_assume_role.json
  managed_policy_arns = [aws_iam_policy.ecs_run_task.arn]
}

resource "aws_iam_policy" "ecs_run_task" {
  name = "ecs_task_role_run_task-${random_uuid.val.id}"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "ecs:DescribeTasks",
          "ecs:RunTask",
          "ecs:ListTasks",
          "iam:PassRole",
          "sqs:receivemessage",
          "sqs:deletemessage",
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}

data "aws_iam_policy_document" "ecs_task_role_assume_role" {
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
resource "aws_iam_role" "execution_role_for_ecs_task" {
  name               = "execution_role_for_ecs_task-${random_uuid.val.id}"
  assume_role_policy = data.aws_iam_policy_document.ecs_execution_role_assume_role.json
  managed_policy_arns = [aws_iam_policy.ecs_execution_role_policy.arn]
}

resource "aws_iam_policy" "ecs_execution_role_policy" {
  name = "ecs_task_execution_role_policy-${random_uuid.val.id}"

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

data "aws_iam_policy_document" "ecs_execution_role_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}
