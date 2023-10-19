provider "aws" {}

// #### S3 ####
// Creates s3 bucket
resource "random_uuid" "val" {
}

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

// #### Application Gateway Lambda #### 
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

// Lambda function - allow lambda to access resources in your AWS account
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
  function_name = "application-gateway-${random_uuid.val.id}"
  role          = aws_iam_role.iam_for_lambda.arn
  handler       = "application-gateway.lambda_handler" # module is name of python file: application

  s3_bucket = aws_s3_bucket.lambda_bucket.id
  s3_key    = aws_s3_object.application_gateway_lambda.key

  source_code_hash = data.archive_file.application_gateway_lambda.output_base64sha256

  runtime = "python3.11"

  environment {
    variables = {
      foo = "bar",
      CLUSTER_ARN = aws_ecs_cluster.pipeline_cluster.arn
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

// #### API Gateway  #### 
resource "aws_apigatewayv2_api" "lambda" {
  name          = "serverless_lambda_gw"
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_stage" "lambda" {
  api_id = aws_apigatewayv2_api.lambda.id

  name        = "serverless_lambda_stage"
  auto_deploy = true

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_gw.arn

    format = jsonencode({
      requestId               = "$context.requestId"
      sourceIp                = "$context.identity.sourceIp"
      requestTime             = "$context.requestTime"
      protocol                = "$context.protocol"
      httpMethod              = "$context.httpMethod"
      resourcePath            = "$context.resourcePath"
      routeKey                = "$context.routeKey"
      status                  = "$context.status"
      responseLength          = "$context.responseLength"
      integrationErrorMessage = "$context.integrationErrorMessage"
      }
    )
  }
}

resource "aws_apigatewayv2_integration" "application_gateway" {
  api_id = aws_apigatewayv2_api.lambda.id

  integration_uri    = aws_lambda_function.application_gateway.invoke_arn
  integration_type   = "AWS_PROXY"
  integration_method = "POST"
}

resource "aws_apigatewayv2_route" "application_gateway_run" {
  api_id = aws_apigatewayv2_api.lambda.id

  route_key = "POST /run"
  target    = "integrations/${aws_apigatewayv2_integration.application_gateway.id}"
}

resource "aws_cloudwatch_log_group" "api_gw" {
  name = "/aws/api_gw/${aws_apigatewayv2_api.lambda.name}"

  retention_in_days = 30
}

resource "aws_lambda_permission" "api_gw" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.application_gateway.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_apigatewayv2_api.lambda.execution_arn}/*/*"
}

// #### ECS Cluster  ####
resource "aws_kms_key" "ecs_cluster" {
  description             = "ecs_cluster_kms_key"
  deletion_window_in_days = 7
}

resource "aws_cloudwatch_log_group" "ecs_cluster" {
  name = "ecs-cluster-log-${random_uuid.val.id}"
}

resource "aws_ecs_cluster" "pipeline_cluster" {
  name = "pipeline-cluster-${random_uuid.val.id}"

  configuration {
    execute_command_configuration {
      kms_key_id = aws_kms_key.ecs_cluster.arn
      logging    = "OVERRIDE"

      log_configuration {
        cloud_watch_encryption_enabled = true
        cloud_watch_log_group_name     = aws_cloudwatch_log_group.ecs_cluster.name
      }
    }
  }
}

// ### EFS ###
// EFS filesystem
resource "aws_efs_file_system" "pipeline" {
  creation_token = "efs-${random_uuid.val.id}"
  encrypted = true

  tags = {
    Name = "efs-${random_uuid.val.id}"
  }
}

// mount target(s)
resource "aws_efs_mount_target" "mnt-1a" {
  file_system_id = aws_efs_file_system.pipeline.id
  subnet_id      = var.mnt_a
}
resource "aws_efs_mount_target" "mnt-1b" {
  file_system_id = aws_efs_file_system.pipeline.id
  subnet_id      = var.mnt_b
}
resource "aws_efs_mount_target" "mnt-1c" {
  file_system_id = aws_efs_file_system.pipeline.id
  subnet_id      = var.mnt_c
}
resource "aws_efs_mount_target" "mnt-1d" {
  file_system_id = aws_efs_file_system.pipeline.id
  subnet_id      = var.mnt_d
}
resource "aws_efs_mount_target" "mnt-1e" {
  file_system_id = aws_efs_file_system.pipeline.id
  subnet_id      = var.mnt_e
}
resource "aws_efs_mount_target" "mnt-1f" {
  file_system_id = aws_efs_file_system.pipeline.id
  subnet_id      = var.mnt_f
}

// ### ECS Task Definition ###
// ECS Task definition
resource "aws_ecs_task_definition" "pipeline" {
  family                = "pipeline-${random_uuid.val.id}"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 1024
  memory                   = 2048
  task_role_arn      = var.task_role_arn
  execution_role_arn = var.execution_role_arn

  container_definitions = jsonencode([
    {
      name      = "pipeline-${random_uuid.val.id}"
      image     = var.image_url
      cpu       = 10
      memory    = 512
      essential = true
      portMappings = [
        {
          containerPort = 8081
          hostPort      = 8081
        }
      ]
      mountPoints = [
        {
          sourceVolume = "pipeline-storage-${random_uuid.val.id}"
          containerPath = "/mnt"
          readOnly = false
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group = "/ecs/pipeline/${random_uuid.val.id}"
          awslogs-region = var.region
          awslogs-stream-prefix = "ecs"
          awslogs-create-group = "true"
        }
      }
    }
  ])

  volume {
    name = "pipeline-storage-${random_uuid.val.id}"

    efs_volume_configuration {
      file_system_id          = aws_efs_file_system.pipeline.id
      root_directory          = "/"
    }
  }
}