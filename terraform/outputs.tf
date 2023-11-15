output "app_ecr_repository" {
  description = "App ECR repository"

  value = aws_ecr_repository.app.repository_url
}

output "post_processor_ecr_repository" {
  description = "Post Processor ECR repository"

  value = aws_ecr_repository.post-processor.repository_url
}

output "app_gateway_url" {
  description = "App Gateway Public URL"

  value = aws_lambda_function_url.app_gateway.function_url
}