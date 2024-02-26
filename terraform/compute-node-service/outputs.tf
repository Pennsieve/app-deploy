output "lambda_function_url" {
  description = "Lambda URL"

  value = aws_lambda_function_url.compute_node_service.function_url
}