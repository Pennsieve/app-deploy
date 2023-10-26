output "function_name" {
  description = "Name of the Lambda function."

  value = aws_lambda_function.application_gateway.function_name
}

output "base_url" {
  description = "Base URL for API Gateway stage."

  value = "${aws_apigatewayv2_stage.lambda.invoke_url}/run"
}

output "ecs_cluster" {
  description = "ECS cluster"

  value = aws_ecs_cluster.pipeline_cluster.arn
}

output "fargate_task_definition" {
  description = "Fargate Task Definition"

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

output "fargate_ecr_repository" {
  description = "Fargate ECR repository"

  value = data.aws_ecr_repository.fargate_task.arn
}

output "post_processor_ecr_repository" {
  description = "Post Processor ECR repository"

  value = data.aws_ecr_repository.post_processor.arn
}