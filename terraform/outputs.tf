output "function_name" {
  description = "Name of the Lambda function."

  value = aws_lambda_function.application_gateway.function_name
}

output "base_url" {
  description = "Base URL for API Gateway stage."

  value = aws_apigatewayv2_stage.lambda.invoke_url
}

output "ecs_cluster_arn" {
  description = "ECS cluster ARN."

  value = aws_ecs_cluster.pipeline_cluster.arn
}