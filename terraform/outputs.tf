output "function_name" {
  description = "Name of the Lambda function."

  value = aws_lambda_function.application_gateway.function_name
}

output "ecs_cluster" {
  description = "ECS cluster"

  value = aws_ecs_cluster.pipeline_cluster.arn
}

output "app_definition" {
  description = "App Task Definition"

  value = aws_ecs_task_definition.pipeline.arn
}

output "subnet_ids" {
  description = "subnet ids comma separated string"

  value = split(",", local.subnet_ids)
}

output "subnet_ids_str" {
  description = "subnet ids comma separated string"

  value = local.subnet_ids
}

output "default_vpc" {
  description = "default VPC"

  value = aws_default_vpc.default.arn
}

output "app_ecr_repository" {
  description = "App ECR repository"

  value = aws_ecr_repository.app.repository_url
}

output "post_processor_ecr_repository" {
  description = "Post Processor ECR repository"

  value = data.aws_ecr_repository.post_processor.arn
}

output "app_gateway_url" {
  description = "App Gateway Public URL"

  value = aws_lambda_function_url.app_gateway.function_url
}