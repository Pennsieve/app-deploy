output "lambda_function_url" {
  description = "Lambda URL"

  value = aws_lambda_function_url.compute_node_service.function_url
}

output "deploy_app_ecr_repository" {
  description = "Deploy App ECR repository"

  value = aws_ecr_repository.app.repository_url
}