// creates an archive and uploads to s3 bucket
data "archive_file" "application_gateway_lambda" {
  type = "zip"

  source_dir  = "${path.module}/application-gateway-lambda"
  output_path = "${path.module}/application-gateway-lambda.zip"
}

// provides an s3 object resource
resource "aws_s3_object" "application_gateway_lambda" {
  bucket = aws_s3_bucket.lambda_bucket.id

  key    = "application-gateway-lambda.zip"
  source = data.archive_file.application_gateway_lambda.output_path

  etag = filemd5(data.archive_file.application_gateway_lambda.output_path)
}

// policy document - gateway lambda
data "aws_iam_policy_document" "iam_policy_document_gateway" {
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
}
