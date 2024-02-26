// Application Gateway Lambda
resource "aws_lambda_function" "compute_node_service" {
  function_name = "compute-node-service-${random_uuid.val.id}"
  role          = aws_iam_role.iam_for_lambda.arn
  handler       = "compute-node-service.lambda_handler" # module is name of python file: application
  description   = "Compute Node Service"

  s3_bucket = aws_s3_bucket.lambda_bucket.id
  s3_key    = aws_s3_object.compute_node_service_lambda.key

  source_code_hash = data.archive_file.compute_node_service_lambda.output_base64sha256

  runtime = "python3.12"
  timeout = 60

  environment {
    variables = {
      REGION = "us-east-1"
      CLUSTER_NAME = aws_ecs_cluster.pipeline_cluster.name
      TASK_DEFINITION_NAME = aws_ecs_task_definition.pipeline.family
      CONTAINER_NAME = aws_ecs_task_definition.pipeline.family # currently same as name of task definition
      SUBNET_IDS = local.subnet_ids
      SECURITY_GROUP_ID = aws_default_security_group.default.id
    }
  }
}

resource "aws_cloudwatch_log_group" "compute_node_service-lambda" {
  name = "/aws/lambda/${aws_lambda_function.compute_node_service.function_name}"

  retention_in_days = 30
}

resource "aws_lambda_function_url" "compute_node_service" {
  function_name      = aws_lambda_function.compute_node_service.function_name
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

resource "aws_iam_role_policy_attachment" "compute_lambda_policy" {
  role       = aws_iam_role.iam_for_lambda.name
  policy_arn = aws_iam_policy.lambda_iam_policy.arn
}

resource "aws_iam_policy" "lambda_iam_policy" {
  name   = "lambda-iam-policy-${random_uuid.val.id}"
  path   = "/"
  policy = data.aws_iam_policy_document.iam_policy_document_compute.json
}

# data
// creates an archive and uploads to s3 bucket
data "archive_file" "compute_node_service_lambda" {
  type = "zip"

  source_dir  = "${path.module}/compute-node-service-lambda"
  output_path = "${path.module}/compute-node-service-lambda.zip"
}

// provides an s3 object resource
resource "aws_s3_object" "compute_node_service_lambda" {
  bucket = aws_s3_bucket.lambda_bucket.id

  key    = "compute-node-service-lambda.zip"
  source = data.archive_file.compute_node_service_lambda.output_path

  etag = filemd5(data.archive_file.compute_node_service_lambda.output_path)
}

// policy document - compute service lambda
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
}

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