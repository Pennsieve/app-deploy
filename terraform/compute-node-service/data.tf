// policy document - compute lambda
data "aws_iam_policy_document" "iam_policy_document_compute" {
  statement {
    sid    = "CloudwatchPermissions"
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = ["*"]
  }

  statement {
    sid    = "ECSTaskPermissions"
    effect = "Allow"
    actions = [
      "ecs:DescribeTasks",
      "ecs:RunTask",
      "ecs:ListTasks"
    ]
    resources = ["*"]
  }

  statement {
    sid    = "ECSPassRole"
    effect = "Allow"
    actions = [
      "iam:PassRole",
    ]
    resources = [
      "*"
    ]
  }

  statement {
    sid    = "IAMPermissions"
    effect = "Allow"
    actions = [
      "iam:CreateUser",
      "iam:GetUser",
      "iam:CreateAccessKey",
      "iam:PutUserPolicy"
    ]
    resources = [
      "*"
    ]
  }
}