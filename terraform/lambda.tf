// Application Gateway Lambda
resource "aws_lambda_function" "application_gateway" {
  function_name = "application-gateway-${random_uuid.val.id}"
  role          = aws_iam_role.iam_for_lambda.arn
  handler       = "application-gateway.lambda_handler" # module is name of python file: application
  description   = "Application: [${var.app_name}]; Environment: [${var.environment}]"

  s3_bucket = aws_s3_bucket.lambda_bucket.id
  s3_key    = aws_s3_object.application_gateway_lambda.key

  source_code_hash = data.archive_file.application_gateway_lambda.output_base64sha256

  runtime = "python3.7" # update to 3.11
  timeout = 60

  environment {
    variables = {
      REGION = var.region
      PENNSIEVE_API_HOST = var.api_host
      API_KEY_SM_NAME = aws_secretsmanager_secret.api_key_secret.name
      SQS_URL = aws_sqs_queue.pipeline_queue.id
    }
  }
}

resource "aws_cloudwatch_log_group" "application_gateway-lambda" {
  name = "/aws/lambda/${aws_lambda_function.application_gateway.function_name}"

  retention_in_days = 30
}

resource "aws_lambda_function_url" "app_gateway" {
  function_name      = aws_lambda_function.application_gateway.function_name
  authorization_type = "NONE"
}