// Application Gateway Lambda
resource "aws_lambda_function" "application_gateway" {
  function_name = "application-gateway-${random_uuid.val.id}"
  role          = aws_iam_role.iam_for_lambda.arn
  handler       = "application-gateway.lambda_handler" # module is name of python file: application

  s3_bucket = aws_s3_bucket.lambda_bucket.id
  s3_key    = aws_s3_object.application_gateway_lambda.key

  source_code_hash = data.archive_file.application_gateway_lambda.output_base64sha256

  runtime = "python3.11"

  environment {
    variables = {
      REGION = var.region
      CLUSTER_NAME = aws_ecs_cluster.pipeline_cluster.name
      TASK_DEFINITION_NAME = aws_ecs_task_definition.pipeline.family
      CONTAINER_NAME = aws_ecs_task_definition.pipeline.family # currently same as name of task definition
      SUBNET_IDS = local.subnet_ids
      SECURITY_GROUP_ID = aws_default_security_group.default.id
    }
  }
}

resource "aws_cloudwatch_log_group" "application_gateway-lambda" {
  name = "/aws/lambda/${aws_lambda_function.application_gateway.function_name}"

  retention_in_days = 30
}