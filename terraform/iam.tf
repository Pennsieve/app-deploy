// Lambda gateway function
// allow lambda to access resources in your AWS account
data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "iam_for_lambda" {
  name               = "iam_for_lambda-${random_uuid.val.id}"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

// attach policy to allow gateway lambda to start an ECS task and to write to Cloudwatch
resource "aws_iam_role_policy_attachment" "lambda_policy_ecs" {
  role       = aws_iam_role.iam_for_lambda.name
  policy_arn = aws_iam_policy.lambda_iam_policy.arn
}

resource "aws_iam_policy" "lambda_iam_policy" {
  name   = "lambda-iam-policy-${random_uuid.val.id}"
  path   = "/"
  policy = data.aws_iam_policy_document.iam_policy_document_gateway.json
}

// ## Main App ##
// ECS task IAM role
resource "aws_iam_role" "task_role_for_ecs_task" {
  name               = "task_role_for_ecs_task-${random_uuid.val.id}"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_role_assume_role.json
  managed_policy_arns = [aws_iam_policy.efs_policy.arn, aws_iam_policy.invoke_lambda.arn, aws_iam_policy.ecs_run_task.arn]
}

resource "aws_iam_policy" "efs_policy" {
  name = "ecs_task_role_efs_policy-${random_uuid.val.id}"

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
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}

resource "aws_iam_policy" "invoke_lambda" {
  name = "ecs_task_invoke_lambda_policy-${random_uuid.val.id}"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = ["lambda:InvokeFunction"]
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

// ## Post Processor ##
// ECS Post processor task IAM role
resource "aws_iam_role" "task_role_for_post_processor" {
  name               = "post_task_role-${random_uuid.val.id}"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_role_assume_role.json
  managed_policy_arns = [aws_iam_policy.efs_policy.arn]
}

// ECS Execution IAM role
resource "aws_iam_role" "execution_role_for_post_processor" {
  name               = "post_iam_role-${random_uuid.val.id}"
  assume_role_policy = data.aws_iam_policy_document.ecs_execution_role_assume_role.json
  managed_policy_arns = [aws_iam_policy.ecs_execution_role_policy.arn]
}

// ## Pre Processor ##
// ECS Pre processor task IAM role
resource "aws_iam_role" "task_role_for_pre_processor" {
  name               = "pre_task_role-${random_uuid.val.id}"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_role_assume_role.json
  managed_policy_arns = [aws_iam_policy.efs_policy.arn]
}

// ECS Execution IAM role
resource "aws_iam_role" "execution_role_for_pre_processor" {
  name               = "pre_iam_role-${random_uuid.val.id}"
  assume_role_policy = data.aws_iam_policy_document.ecs_execution_role_assume_role.json
  managed_policy_arns = [aws_iam_policy.ecs_execution_role_policy.arn]
}