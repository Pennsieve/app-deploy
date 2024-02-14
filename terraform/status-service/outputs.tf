output "lambda_function_url" {
  description = "Lambda URL"

  value = aws_lambda_function_url.status_service.function_url
}