output "function_name" {
  description = "Name of the Lambda function."

  value = aws_lambda_function.application_gateway.function_name
}
