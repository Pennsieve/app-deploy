// Application Gateway Lambda
resource "aws_lambda_function" "application_state" {
  function_name = "application-state-${random_uuid.val.id}"
  role          = aws_iam_role.iam_for_lambda.arn
  handler       = "application-state.lambda_handler" # module is name of python file: application
  description   = "Application State Management"

  s3_bucket = aws_s3_bucket.lambda_bucket.id
  s3_key    = aws_s3_object.application_state_lambda.key

  source_code_hash = data.archive_file.application_state_lambda.output_base64sha256

  runtime = "python3.7" # update to 3.11
  timeout = 60

  environment {
    variables = {
      APPLICATIONS_TABLE = aws_dynamodb_table.applications_table.name,
    }
  }
}

resource "aws_cloudwatch_log_group" "application_state-lambda" {
  name = "/aws/lambda/${aws_lambda_function.application_state.function_name}"

  retention_in_days = 30
}

resource "aws_lambda_function_url" "app_state" {
  function_name      = aws_lambda_function.application_state.function_name
  authorization_type = "NONE"
}

# IAM
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

// attach policy to allow state lambda to start an ECS task and to write to Cloudwatch
resource "aws_iam_role_policy_attachment" "lambda_policy_ecs" {
  role       = aws_iam_role.iam_for_lambda.name
  policy_arn = aws_iam_policy.lambda_iam_policy.arn
}

resource "aws_iam_policy" "lambda_iam_policy" {
  name   = "lambda-iam-policy-${random_uuid.val.id}"
  path   = "/"
  policy = data.aws_iam_policy_document.iam_policy_document_state.json
}

# data
// creates an archive and uploads to s3 bucket
data "archive_file" "application_state_lambda" {
  type = "zip"

  source_dir  = "${path.module}/application-state-lambda"
  output_path = "${path.module}/application-state-lambda.zip"
}

// provides an s3 object resource
resource "aws_s3_object" "application_state_lambda" {
  bucket = aws_s3_bucket.lambda_bucket.id

  key    = "application-state-lambda.zip"
  source = data.archive_file.application_state_lambda.output_path

  etag = filemd5(data.archive_file.application_state_lambda.output_path)
}

// policy document - state lambda
data "aws_iam_policy_document" "iam_policy_document_state" {
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
    sid    = "ECSPassRole"
    effect = "Allow"
    actions = [
      "iam:PassRole",
    ]
    resources = [
      "*"
    ]
  }

  // TODO: specify resource
  statement {
    sid    = "S3Permissions"
    effect = "Allow"
    actions = [
      "s3:GetObject",
    ]
    resources = ["*"]
  }

   statement {
    sid = "LambdaAccessToDynamoDB"
    effect = "Allow"

    actions = [
      "dynamodb:BatchGetItem",
      "dynamodb:GetItem",
      "dynamodb:Query",
      "dynamodb:Scan",
      "dynamodb:BatchWriteItem",
      "dynamodb:PutItem",
      "dynamodb:UpdateItem"
    ]

    resources = [
      aws_dynamodb_table.applications_table.arn,
      "${aws_dynamodb_table.applications_table.arn}/*"
    ]

  }
}

# s3
// S3 bucket
resource "aws_s3_bucket" "lambda_bucket" {
  bucket = random_uuid.val.id
}

resource "aws_s3_bucket_ownership_controls" "lambda_bucket" {
  bucket = aws_s3_bucket.lambda_bucket.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "bucket_acl" {
  depends_on = [aws_s3_bucket_ownership_controls.lambda_bucket]

  bucket = aws_s3_bucket.lambda_bucket.id
  acl    = "private"
}