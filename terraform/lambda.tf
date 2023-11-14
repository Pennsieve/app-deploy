// Application Gateway Lambda
resource "aws_lambda_function" "application_gateway" {
  function_name = "application-gateway-${random_uuid.val.id}"
  role          = aws_iam_role.iam_for_lambda.arn
  handler       = "application-gateway.lambda_handler" # module is name of python file: application

  s3_bucket = aws_s3_bucket.lambda_bucket.id
  s3_key    = aws_s3_object.application_gateway_lambda.key

  source_code_hash = data.archive_file.application_gateway_lambda.output_base64sha256

  runtime = "python3.7" # update to 3.11
  timeout = 60

  environment {
    variables = {
      REGION = var.region
      CLUSTER_NAME = aws_ecs_cluster.pipeline_cluster.name
      TASK_DEFINITION_NAME = aws_ecs_task_definition.pipeline.family
      CONTAINER_NAME = aws_ecs_task_definition.pipeline.family # currently same as name of task definition
      SUBNET_IDS = local.subnet_ids
      SECURITY_GROUP_ID = aws_default_security_group.default.id
      # POST_PROCESSOR_INVOKE_ARN = aws_lambda_function.post_processor.arn
      TASK_DEFINITION_NAME_POST = aws_ecs_task_definition.post-processor.family
      CONTAINER_NAME_POST = aws_ecs_task_definition.post-processor.family
      PENNSIEVE_API_KEY = var.api_key
      PENNSIEVE_API_SECRET = var.api_secret
      PENNSIEVE_API_HOST = var.api_host
      PENNSIEVE_API_HOST2 = var.api_host2
      PENNSIEVE_AGENT_HOME = var.pennsieve_agent_home
      PENNSIEVE_UPLOAD_BUCKET=var.pennsieve_upload_bucket
    }
  }
}

resource "aws_cloudwatch_log_group" "application_gateway-lambda" {
  name = "/aws/lambda/${aws_lambda_function.application_gateway.function_name}"

  retention_in_days = 30
}

// Post-processor Lambda
# resource "aws_lambda_function" "post_processor" {
#   function_name = "post-processor-${random_uuid.val.id}"
#   role          = aws_iam_role.iam_for_post_processor_lambda.arn

#   image_uri = "${data.aws_ecr_repository.post_processor.repository_url}:latest"
#   package_type = "Image"
#   memory_size = 1024
#   timeout = 900

#   file_system_config {
#     # EFS file system access point ARN
#     arn = aws_efs_access_point.access_point_for_post_lambda.arn

#     # Local mount path inside the lambda function. Must start with '/mnt/'.
#     local_mount_path = "/mnt/efs"
#   }

#   vpc_config {
#     # Every subnet should be able to reach an EFS mount target in the same Availability Zone. Cross-AZ mounts are not permitted.
#     subnet_ids         = local.subnet_ids_list
#     security_group_ids = [aws_default_security_group.default.id]
#   }

#   environment {
#     variables = {
#       REGION = var.region
#       PENNSIEVE_API_KEY = var.api_key
#       PENNSIEVE_API_SECRET = var.api_secret
#       PENNSIEVE_API_HOST = var.api_host
#       HOME = var.pennsieve_agent_home
#     }
#   }
# }

# resource "aws_cloudwatch_log_group" "post_processor-lambda" {
#   name = "/aws/lambda/${aws_lambda_function.post_processor.function_name}"

#   retention_in_days = 30
# }

resource "aws_lambda_function_url" "app_gateway" {
  function_name      = aws_lambda_function.application_gateway.function_name
  authorization_type = "NONE"
}