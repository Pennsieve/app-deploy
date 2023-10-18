provider "aws" {}

// Creates s3 bucket
resource "random_uuid" "val" {
}

resource "aws_s3_bucket" "lambda_bucket" {
  bucket = random_uuid.val.result
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

// Application Gateway Lambda
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

// Lambda function
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
  name               = "iam_for_lambda"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

resource "aws_lambda_function" "application_gateway" {
  function_name = "application-gateway-lambda-${random_uuid.val.result}"
  role          = aws_iam_role.iam_for_lambda.arn
  handler       = "application-gateway.lambda_handler" # module is name of python file: application

  s3_bucket = aws_s3_bucket.lambda_bucket.id
  s3_key    = aws_s3_object.application_gateway_lambda.key

  source_code_hash = data.archive_file.application_gateway_lambda.output_base64sha256

  runtime = "python3.11"

  environment {
    variables = {
      foo = "bar"
    }
  }
}

resource "aws_cloudwatch_log_group" "application_gateway-lambda" {
  name = "/aws/lambda/${aws_lambda_function.application_gateway.function_name}"

  retention_in_days = 30
}

// attach policy to role to allow function to write to amazon cloudwatch
resource "aws_iam_role_policy_attachment" "lambda_policy" {
  role       = aws_iam_role.iam_for_lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}
